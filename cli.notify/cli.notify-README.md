# cli.notify

Bashly-authored notification adapter for Hyprland binds, libnotify emission, and Lucent/Freedesktop notification-server inspection.

## Contract

```txt
Hyprland bind
  -> cli.notify
  -> state mutation / state readback
  -> libnotify notification
  -> Lucent D-Bus notification server
```

`cli.notify` is an adapter CLI. It is not a notification daemon and does not replace Lucent.

## Boundary

### Owns

- Keyboard-bind friendly notification commands.
- Audio and brightness mutation wrappers.
- State readback after each mutation.
- Stable replacement channels for repeated key events.
- Freedesktop `org.freedesktop.Notifications` server inspection.
- Lucent-focused diagnostics derived from the active notification server.
- JSON output for status, diagnostics, and testable command results.

### Does not own

- Notification rendering.
- GTK widgets or layer-shell surfaces.
- Lucent lifecycle.
- Hyprland visual rules.
- Long-running background state.
- Compositor-specific rendering behavior.

```txt
Hyprland:
  owns binds and layer rules

cli.notify:
  owns event/action adaptation

Lucent:
  owns D-Bus notification service and rendering
```

Lucent remains the D-Bus-activated notification server. Hyprland remains the compositor and visual-policy owner.

## Current repo boundary

```txt
bashly.sh:
  cli.notify/stub exists

dotfiles:
  private_dot_config/hypr/modules/binds.lua
  private_dot_config/hypr/modules/notifications.lua
  private_dot_config/lucent/config.toml
```

Current Hyprland binds call `brightnessctl` and `wpctl` directly. The target is to route those binds through `cli.notify` so mutation, readback, replacement, and notification emission stay coupled.

## Command surface

```txt
cli.notify
  send
  volume
    up
    down
    mute
    status
  brightness
    up
    down
    status
  dbus
    info
    capabilities
    owner
    ping
  lucent
    status
    config
  doctor
```

## Command intent

| Command | Purpose | Mutates state | Emits notification | Prints JSON |
|---|---|---:|---:|---:|
| `cli.notify send` | Generic libnotify facade | no | yes | optional |
| `cli.notify volume up` | Raise default sink volume | yes | yes | optional |
| `cli.notify volume down` | Lower default sink volume | yes | yes | optional |
| `cli.notify volume mute` | Toggle default sink mute | yes | yes | optional |
| `cli.notify volume status` | Read default sink volume/mute | no | no | yes |
| `cli.notify brightness up` | Raise display brightness | yes | yes | optional |
| `cli.notify brightness down` | Lower display brightness | yes | yes | optional |
| `cli.notify brightness status` | Read brightness level | no | no | yes |
| `cli.notify dbus info` | Read notification server information | no | no | yes |
| `cli.notify dbus capabilities` | Read server capabilities | no | no | yes |
| `cli.notify dbus owner` | Read current bus owner for `org.freedesktop.Notifications` | no | no | yes |
| `cli.notify dbus ping` | Check whether a notification server responds | no | no | yes |
| `cli.notify lucent status` | Derived Lucent-focused status | no | no | yes |
| `cli.notify lucent config` | Read Lucent config from XDG path | no | no | yes |
| `cli.notify doctor` | Validate tools, D-Bus, Lucent, and bind prerequisites | no | no | yes |

## Notification envelope

Every emitted notification should normalize through one internal envelope before calling `notify-send` or direct D-Bus.

```txt
NotificationEnvelope:
  channel: string          # replacement key: volume, brightness, pomodoro, etc.
  app_name: string         # default: cli.notify
  summary: string          # required
  body: string             # optional
  icon: string             # optional icon-theme name or path
  urgency: low|normal|critical
  timeout_ms: int          # -1 default, 0 persistent, positive timeout
  transient: bool
  replace: bool
  hints: map[string]Hint
  actions: list[Action]
```

Freedesktop mapping:

```txt
Notify(
  app_name,
  replaces_id,
  app_icon,
  summary,
  body,
  actions,
  hints,
  expire_timeout,
) -> notification_id
```

`channel` is adapter-local. It decides whether a repeated event should replace an earlier notification.

## Replacement channels

High-frequency bind events must not stack notifications.

Runtime state:

```txt
${XDG_RUNTIME_DIR}/cli.notify/ids/<channel>
```

Replacement-capable `notify-send` path:

```sh
notify-send   --app-name="cli.notify"   --print-id   --replace-id="$previous_id"   --urgency="$urgency"   --expire-time="$timeout_ms"   --icon="$icon"   --hint="string:x-canonical-private-synchronous:cli.notify:${channel}"   --transient   "$summary" "$body"
```

Rules:

- If no previous ID exists, send with replace ID `0` or omit `--replace-id`.
- If the server returns a new ID, store it for the channel.
- If `notify-send --print-id` is unavailable, degrade to fire-and-forget plus the synchronous/vendor hint.
- Unknown hints are optional; notification servers may ignore them.

## D-Bus and Lucent probes

Lucent implements the standard Freedesktop notification service:

```txt
org.freedesktop.Notifications
/org/freedesktop/Notifications
org.freedesktop.Notifications
```

### Server information

```sh
busctl --user call   org.freedesktop.Notifications   /org/freedesktop/Notifications   org.freedesktop.Notifications   GetServerInformation
```

Normalized JSON:

```json
{
  "ok": true,
  "server": {
    "name": "Lucent",
    "vendor": "...",
    "version": "...",
    "spec_version": "..."
  }
}
```

### Capabilities

```sh
busctl --user call   org.freedesktop.Notifications   /org/freedesktop/Notifications   org.freedesktop.Notifications   GetCapabilities
```

Normalized JSON:

```json
{
  "ok": true,
  "capabilities": ["body", "actions"]
}
```

### Lucent status

`cli.notify lucent status --json` is derived, not hard-coded.

```json
{
  "ok": true,
  "service": "org.freedesktop.Notifications",
  "server_available": true,
  "server_name": "Lucent",
  "is_lucent": true,
  "activation_file_exists": true,
  "config_path": "/home/user/.config/lucent/config.toml",
  "config_exists": true
}
```

If another daemon owns the bus, `is_lucent` should be `false` and the command should still return a successful diagnostic unless the probe itself fails.

## Hyprland integration

### Current direct binds

```lua
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"))

hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeatable = true }
)
```

### Target binds

```lua
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("cli.notify brightness up"), {
  repeatable = true,
})

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("cli.notify brightness down"), {
  repeatable = true,
})

hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("cli.notify volume up"),
  { locked = true, repeatable = true }
)

hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("cli.notify volume down"),
  { locked = true, repeatable = true }
)

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("cli.notify volume mute"), {
  locked = true,
})
```

The existing Lucent visual policy stays in:

```txt
private_dot_config/hypr/modules/notifications.lua
```

Visual-policy boundary:

```txt
Hyprland layer rule
  -> namespace lucent-notification
  -> blur / ignore_alpha
```

## Runtime dependencies

Hard runtime dependencies:

- `bash`
- `notify-send` from libnotify
- `wpctl` for volume commands
- `brightnessctl` for brightness commands
- `busctl` or `gdbus` for D-Bus status commands

Optional runtime dependencies:

- `jq` for robust JSON construction if shell-only JSON generation is not enough
- `python` for TOML inspection of Lucent config if no TOML-specific shell tool is available

Build/development dependencies:

- `bashly`
- `shellharden`
- `shfmt`
- `shellcheck`
- `cue`
- optional `bats` / `shellspec`

## Exit-code contract

| Code | Meaning |
|---:|---|
| `0` | command succeeded |
| `1` | command failed at runtime |
| `2` | dependency missing |
| `64` | usage error |
| `69` | notification server unavailable |
| `70` | internal adapter error |
| `75` | temporary failure; retry may work |

## Output contract

Mutation commands are quiet by default.

```sh
cli.notify volume up
cli.notify brightness down
```

JSON mode is explicit.

```sh
cli.notify volume up --json
cli.notify dbus info --json
cli.notify doctor --json
```

Example mutation JSON:

```json
{
  "ok": true,
  "kind": "volume",
  "action": "up",
  "value_percent": 45,
  "muted": false,
  "notification": {
    "emitted": true,
    "channel": "volume",
    "id": 12,
    "replaced": true
  }
}
```

Example failure JSON:

```json
{
  "ok": false,
  "error": {
    "code": "missing_dependency",
    "message": "notify-send not found",
    "dependency": "notify-send"
  }
}
```

## Bashly source layout

```txt
cli.notify/
  bashly.yml
  src/
    root_command.sh
    lib/
      deps.sh
      json.sh
      state.sh
      notify.sh
      dbus.sh
      volume.sh
      brightness.sh
      lucent.sh
    send_command.sh
    volume_up_command.sh
    volume_down_command.sh
    volume_mute_command.sh
    volume_status_command.sh
    brightness_up_command.sh
    brightness_down_command.sh
    brightness_status_command.sh
    dbus_info_command.sh
    dbus_capabilities_command.sh
    dbus_owner_command.sh
    dbus_ping_command.sh
    lucent_status_command.sh
    lucent_config_command.sh
    doctor_command.sh
  cli.notify
```

Generated Bashly output should not be manually edited. Durable changes belong in `bashly.yml` and `src/*.sh`.

## CUE/schema-first authority

The command contract should exist before Bashly implementation details.

Authority file:

```txt
schema/cli_notify.cue
```

Suggested schema shape:

```cue
#CliNotifyCommand: {
  name: string
  path: [...string]
  mutatesSystem: bool
  emitsNotification: bool
  jsonOutput: bool
  dependencies: [...string]
}

#NotificationEnvelope: {
  channel: string
  appName: *"cli.notify" | string
  summary: string
  body?: string
  icon?: string
  urgency: *"normal" | "low" | "critical"
  timeoutMs: *1500 | int
  transient: *true | bool
  replace: *true | bool
}
```

Projected outputs can later include:

```txt
cli.notify/bashly.yml
cli.notify/README.md
.codex/frames/cli-notify.md
.codex/generated/cli-notify-command-index.json
```

## Acceptance checks

```sh
cli.notify doctor --json
cli.notify dbus info --json
cli.notify dbus capabilities --json
cli.notify send --summary "cli.notify" --body "test" --json
cli.notify volume status --json
cli.notify brightness status --json
```

Hyprland bind checks:

```sh
cli.notify volume up
cli.notify volume down
cli.notify volume mute
cli.notify brightness up
cli.notify brightness down
```

Expected behavior:

- Volume and brightness change exactly once per bind event.
- Repeated volume/brightness binds replace the previous notification instead of stacking.
- Lucent displays notifications through D-Bus activation.
- `cli.notify dbus info --json` reports the active notification server.
- If the active server is not Lucent, diagnostics report that instead of failing silently.

## Future umbrella CLI

Stable dotted tools remain valid even if a later umbrella CLI exists.

```txt
Phase 1:
  cli.notify
  cli.dot
  cli.hypr

Phase 2:
  cli notify ...
  cli dot ...
  cli hypr ...

Phase 3:
  cli.notify -> cli notify "$@"
  cli.dot    -> cli dot "$@"
  cli.hypr   -> cli hypr "$@"
```

## References

- Lucent: https://github.com/CPT-Dawn/Lucent
- Desktop Notifications Specification: https://specifications.freedesktop.org/notification-spec/latest-single/
- Arch `notify-send(1)`: https://man.archlinux.org/man/notify-send.1
- Debian `notify-send(1)`: https://manpages.debian.org/notify-send
