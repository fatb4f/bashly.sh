# cli.notify

Bashly-authored dispatcher for Hyprland binds, namespace-based backlight/sound actions, and Lucent-rendered GTK4 shell-layer icon notifications.

## Agent Surface

This repository's actual agent-sdk surface is the CUE profile under `agent-sdk/cue/profiles/bash-cli/` and the generated projection in `meta/agent/generated/project-graph.json`.

Relevant authority files:

- `agent.cue`
- `agent-sdk/cue/profiles/bash-cli/repo.cue`
- `agent-sdk/cue/profiles/bash-cli/skills.cue`
- `agent-sdk/cue/profiles/bash-cli/workflow.cue`
- `agent-sdk/cue/profiles/bash-cli/surfaces.cue`
- `meta/agent/generated/project-graph.json`

Generated frame outputs are projection targets, not hand-edited source files.

## Contract

```txt
Hyprland bind
  -> cli.notify namespace action
  -> current-percent helper
  -> Lucent render request
  -> GTK4 shell-layer icon notification
```

`cli.notify` is a dispatcher. It does not call external mutator executables, and it does not render notifications itself.

## Boundary

### Owns

- Keyboard-bind friendly namespace actions.
- `backlight` and `sound` namespaces with `up` and `down` arguments.
- Current-percent normalization before handoff.
- Lucent request shaping for icon notifications.
- Stable namespace keys for repeated key events.

### Does not own

- Notification rendering.
- GTK widgets or layer-shell surfaces.
- Lucent lifecycle.
- Hyprland visual rules.
- External device-control executables.
- Compositor-specific rendering behavior.

```txt
Hyprland:
  owns binds and layer rules

cli.notify:
  owns namespace/action adaptation

Lucent:
  owns GTK4 shell-layer formatting and rendering
```

Lucent remains the renderer. Hyprland remains the compositor and visual-policy owner.

## Current repo boundary

```txt
bashly.sh:
  src/cli.notify/cli.notify-README.md
  src/cli.notify/cli.notify-IMPLEMENTATION_MILESTONES.md
  src/cli.notify/src/bashly.yml

dotfiles:
  private_dot_config/hypr/modules/binds.lua
  private_dot_config/hypr/modules/notifications.lua
  private_dot_config/lucent/config.toml
```

Current Hyprland binds should call `cli.notify backlight up|down` and `cli.notify sound up|down`. The target is to keep current-percent lookup and Lucent rendering coupled to the key event.

## Namespace surface

```txt
cli.notify
  backlight
    up
    down
  sound
    up
    down
```

The current-percent helper is internal. It normalizes the active namespace state before the request is sent to Lucent.

## Namespace intent

| Namespace | Args | Purpose |
|---|---|---|
| `backlight` | `up`, `down` | Adjust backlight state and report the current percent to Lucent. |
| `sound` | `up`, `down` | Adjust sound state and report the current percent to Lucent. |

## Lucent handoff

Every action normalizes through one internal envelope before calling Lucent.

```txt
NotificationRequest:
  namespace: string        # backlight or sound
  action: up|down
  percent: int
  summary: string
  body: string             # optional
  icon: string             # optional icon name or path
  transient: bool
```

Lucent mapping:

```txt
Normalize request
  -> format GTK4 shell-layer icon notification
  -> render through Lucent
```

Repeated events should key by namespace so Lucent can update the same notification instead of stacking new ones.

## Hyprland integration

### Target binds

```lua
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("cli.notify backlight up"), {
  repeatable = true,
})

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("cli.notify backlight down"), {
  repeatable = true,
})

hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("cli.notify sound up"),
  { locked = true, repeatable = true }
)

hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("cli.notify sound down"),
  { locked = true, repeatable = true }
)
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

- `bash`
- Lucent render support
- Hyprland key-bind integration

Build/development dependencies:

- `bashly`
- `shellharden`
- `shfmt`
- `shellcheck`
- `cue`
- optional `bats`

## Bashly source layout

```txt
src/cli.notify/
  src/
    bashly.yml
    root_command.sh
    lib/
      percent.sh
      request.sh
      lucent.sh
    backlight_up_command.sh
    backlight_down_command.sh
    sound_up_command.sh
    sound_down_command.sh
  cli.notify
```

Generated Bashly output should not be manually edited. Durable changes belong in `bashly.yml` and `src/*.sh`.

## CUE/schema-first authority

The namespace contract should exist before Bashly implementation details.

Authority file:

```txt
schema/cli_notify.cue
```

Suggested schema shape:

```cue
#CliNotifyNamespace: {
  name: string
  actions: [...string]
  dependencies: [...string]
}

#NotificationRequest: {
  namespace: string
  action: "up" | "down"
  percent: int
  summary: string
  body?: string
  icon?: string
  transient: bool | *true
}
```

Projected outputs can later include:

```txt
meta/agent/generated/project-graph.json
meta/agent/frames/repo-frame.md
meta/agent/frames/skills.md
meta/agent/frames/workflow.md
```

## Acceptance checks

```sh
cli.notify backlight up
cli.notify backlight down
cli.notify sound up
cli.notify sound down
```

Hyprland bind checks:

```sh
cli.notify backlight up
cli.notify backlight down
cli.notify sound up
cli.notify sound down
```

Expected behavior:

- Backlight and sound actions change exactly once per bind event.
- Repeated backlight/sound binds update the same Lucent notification by namespace instead of stacking.
- Lucent formats the icon notification as a GTK4 shell-layer surface.
- The current-percent helper is applied before handoff.

## Future umbrella CLI

Stable dotted tools remain valid even if a later umbrella CLI exists.

```txt
Phase 1:
  cli.notify
  cli.backlight
  cli.sound

Phase 2:
  cli notify ...
  cli backlight ...
  cli sound ...

Phase 3:
  cli.notify -> cli notify "$@"
  cli.backlight -> cli backlight "$@"
  cli.sound -> cli sound "$@"
```

## References

- Lucent: https://github.com/CPT-Dawn/Lucent
- Desktop Notifications Specification: https://specifications.freedesktop.org/notification-spec/latest-single/
- Lucent: https://github.com/CPT-Dawn/Lucent
- GTK: https://docs.gtk.org/gtk4/
