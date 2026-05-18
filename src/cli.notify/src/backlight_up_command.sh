# shellcheck shell=bash
cli_notify_backlight_up_command_impl() {
  cli_notify_emit_request backlight up "$(cli_notify_backlight_percent)"
}

cli_notify_backlight_up_command_impl
