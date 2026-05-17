# Pomodoro Service Architecture

This document defines the reference architecture for `pomodoroctl` and its
systemd-user units.

The goal is a robust, idempotent Pomodoro state machine that:

- survives restarts without replaying stale timer history
- drives work and break transitions through systemd units
- blocks session unlock while a break is active
- keeps all state transitions single-writer and easy to audit

## Contract

The public command surface is:

- `pomodoroctl start`
- `pomodoroctl stop`
- `pomodoroctl status`
- `pomodoroctl skip`
- `pomodoroctl enter-work`
- `pomodoroctl finish-work`
- `pomodoroctl finish-break`

The implementation is expected to be callable both from Bashly-generated
commands and from systemd service units.

## Files And Units

### Persistent state

- `XDG_STATE_HOME/pomodoroctl/state.env`
- owns the canonical Pomodoro state machine values
- written only by `pomodoroctl`

### Runtime lockout marker

- `XDG_RUNTIME_DIR/pomodoro/break-until`
- contains a Unix epoch timestamp for the active break end
- read by `session-unlock`
- written only while a break is active
- removed when the break ends or when the cycle is stopped

### Systemd units

- `pomodoro-cycle.service`
- `pomodoro-work.timer`
- `pomodoro-work.service`
- `pomodoro-short-break.timer`
- `pomodoro-long-break.timer`
- `pomodoro-break.service`

### Session integration

- `locked-session-halt.timer`
- `session-lock.service`
- `session-unlock`

## State Model

The machine has three phases:

- `idle`
- `work`
- `break`

Canonical fields:

- `PHASE`
- `CYCLE`
- `BREAK_KIND`
- `WORK_STARTED_AT`
- `WORK_UNTIL`
- `BREAK_STARTED_AT`
- `BREAK_UNTIL`
- `LAST_TRANSITION_AT`

Invariants:

- only one phase is active at a time
- a phase transition always rewrites the persistent state
- a break always has a concrete `BREAK_UNTIL`
- `session-unlock` must be able to reject unlocks by inspecting
  `break-until` without reading systemd history

## Unit Graph

```txt
pomodoroctl start
  -> systemctl --user restart pomodoro-cycle.service
  -> pomodoro-cycle.service
  -> pomodoroctl enter-work
  -> pomodoro-work.timer
  -> pomodoro-work.service

pomodoro-work.timer
  -> after work interval
  -> pomodoro-work.service
  -> pomodoroctl finish-work
  -> pomodoro-short-break.timer | pomodoro-long-break.timer
  -> pomodoro-break.service

pomodoro-short-break.timer
  -> after short break interval
  -> pomodoro-break.service
  -> pomodoroctl finish-break
  -> pomodoro-work.timer

pomodoro-long-break.timer
  -> after long break interval
  -> pomodoro-break.service
  -> pomodoroctl finish-break
  -> pomodoro-work.timer
```

## Transition Rules

### Start

`pomodoroctl start`:

- clears stale timer failure state
- restarts `pomodoro-cycle.service`
- begins a fresh work interval

### Enter work

`pomodoroctl enter-work`:

- sets `PHASE=work`
- computes `WORK_UNTIL`
- clears break fields
- removes any runtime break lockout marker
- stops break timers
- arms `pomodoro-work.timer`

### Finish work

`pomodoroctl finish-work`:

- only acts when `PHASE=work`
- increments `CYCLE`
- chooses short or long break from `LONG_BREAK_EVERY`
- writes `BREAK_KIND` and `BREAK_UNTIL`
- publishes `break-until` in the runtime directory
- arms the selected break timer

### Finish break

`pomodoroctl finish-break`:

- only acts when `PHASE=break`
- removes `break-until`
- clears break timer state
- re-enters work

### Stop

`pomodoroctl stop`:

- stops all work and break timers
- stops `pomodoro-cycle.service` unless `--keep-anchor` is set
- resets persistent state to `idle`
- removes `break-until`

## Robustness Mechanism

The robust mechanism is based on a split between persistent state and runtime
lockout state.

### Persistent state

The state file is used for:

- status output
- cycle count
- phase recovery after restart
- human-readable diagnostics

It is not used as the unlock gate.

### Runtime lockout state

The runtime `break-until` file is the unlock gate because:

- it is cheap to read from `session-unlock`
- it expires naturally with the user session runtime directory
- it does not rely on replaying systemd history
- it can be removed immediately when a break ends

This prevents stale timer history from causing accidental unlocks or re-locks.

## Failure Handling

### Restart safety

If `pomodoroctl` or systemd restarts:

- the next command loads the persisted state
- phase transitions are re-established from explicit state, not timer memory
- timers are always stopped before the replacement timer is armed

### Duplicate transition safety

If a timer edge fires twice or a stale service runs late:

- transition handlers verify the current `PHASE`
- handlers become no-ops when the phase no longer matches

### Unlock safety

`session-unlock` should:

- read `break-until`
- deny unlock when the timestamp is still in the future
- only remove the runtime marker after the break has expired

### Systemd-off mode

When `POMODOROCTL_NO_SYSTEMD=1`:

- state transitions still work
- timers are not touched
- status remains available

This mode is for local diagnostics and tests, not the normal runtime path.

## Required Artifacts

The implementation should provide the following files or equivalents:

- `src/cli.pomodoro/src/bashly.yml`
- `src/cli.pomodoro/src/commands/start.sh`
- `src/cli.pomodoro/src/commands/stop.sh`
- `src/cli.pomodoro/src/commands/status.sh`
- `src/cli.pomodoro/src/commands/skip.sh`
- `src/cli.pomodoro/src/commands/enter-work.sh`
- `src/cli.pomodoro/src/commands/finish-work.sh`
- `src/cli.pomodoro/src/commands/finish-break.sh`
- `src/cli.pomodoro/ref/pomodoro-cycle.service`
- `src/cli.pomodoro/ref/pomodoro-work.timer`
- `src/cli.pomodoro/ref/pomodoro-work.service`
- `src/cli.pomodoro/ref/pomodoro-short-break.timer`
- `src/cli.pomodoro/ref/pomodoro-long-break.timer`
- `src/cli.pomodoro/ref/pomodoro-break.service`

## Exit Criteria

The architecture is complete when:

- starting the cycle only creates one active work timer
- work and break timers never rearm from stale state
- unlock is blocked while `break-until` is in the future
- the cycle can be stopped and restarted without manual cleanup
- `status` can describe the current phase without touching systemd history

