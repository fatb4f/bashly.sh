# shellcheck shell=bash
cli_notify_sound_up_command_impl() {
  cli_notify_emit_request sound up "$(cli_notify_sound_percent)"
}

cli_notify_sound_up_command_impl
