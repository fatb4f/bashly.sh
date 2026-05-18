# shellcheck shell=bash
cli_notify_render_request() {
  local namespace action percent summary body icon transient

  namespace="$1"
  action="$2"
  percent="$3"
  summary="$4"
  body="$5"
  icon="$6"
  transient="$7"

  printf '%s\n' "namespace=$namespace"
  printf '%s\n' "action=$action"
  printf '%s\n' "percent=$percent"
  printf '%s\n' "summary=$summary"
  printf '%s\n' "body=$body"
  printf '%s\n' "icon=$icon"
  printf '%s\n' "transient=$transient"
}

cli_notify_send_request() {
  local namespace action percent summary body icon transient lucent_cmd

  namespace="$1"
  action="$2"
  percent="$3"
  summary="$4"
  body="$5"
  icon="$6"
  transient="$7"
  lucent_cmd="${CLI_NOTIFY_LUCENT_CMD:-}"

  if [[ -n "$lucent_cmd" ]] && command -v "$lucent_cmd" > /dev/null 2>&1; then
    cli_notify_render_request \
      "$namespace" \
      "$action" \
      "$percent" \
      "$summary" \
      "$body" \
      "$icon" \
      "$transient" | "$lucent_cmd"
    return $?
  fi

  cli_notify_render_request \
    "$namespace" \
    "$action" \
    "$percent" \
    "$summary" \
    "$body" \
    "$icon" \
    "$transient"
}
