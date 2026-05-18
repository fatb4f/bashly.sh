# shellcheck shell=bash
cli_notify_backlight_down_command_impl() {
  cli_notify_emit_request backlight down "$(cli_notify_backlight_percent)"
}

cli_notify_backlight_down_command_impl
