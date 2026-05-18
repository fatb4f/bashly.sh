# shellcheck shell=bash
cli_notify_namespace_label() {
  case "$1" in
    backlight) printf '%s\n' "Backlight" ;;
    sound) printf '%s\n' "Sound" ;;
    *)
      printf '%s\n' "${1^}"
      ;;
  esac
}

cli_notify_action_label() {
  case "$1" in
    up) printf '%s\n' "Up" ;;
    down) printf '%s\n' "Down" ;;
    *)
      printf '%s\n' "${1^}"
      ;;
  esac
}

cli_notify_summary() {
  local namespace percent

  namespace="$1"
  percent="$2"

  printf '%s %s%%\n' "$(cli_notify_namespace_label "$namespace")" "$percent"
}

cli_notify_body() {
  local action

  action="$1"

  case "$action" in
    up) printf '%s\n' "Increase" ;;
    down) printf '%s\n' "Decrease" ;;
    *)
      printf '%s\n' "$(cli_notify_action_label "$action")"
      ;;
  esac
}

cli_notify_icon() {
  local namespace percent

  namespace="$1"
  percent="$2"

  case "$namespace" in
    backlight)
      if ((percent < 25)); then
        printf '%s\n' "display-brightness-low-symbolic"
      elif ((percent < 75)); then
        printf '%s\n' "display-brightness-medium-symbolic"
      else
        printf '%s\n' "display-brightness-high-symbolic"
      fi
      ;;
    sound)
      if ((percent <= 0)); then
        printf '%s\n' "audio-volume-muted-symbolic"
      elif ((percent < 34)); then
        printf '%s\n' "audio-volume-low-symbolic"
      elif ((percent < 67)); then
        printf '%s\n' "audio-volume-medium-symbolic"
      else
        printf '%s\n' "audio-volume-high-symbolic"
      fi
      ;;
    *)
      printf '%s\n' "dialog-information-symbolic"
      ;;
  esac
}

cli_notify_emit_request() {
  local namespace action percent summary body icon transient

  namespace="$1"
  action="$2"
  percent="$3"
  summary="$(cli_notify_summary "$namespace" "$percent")"
  body="$(cli_notify_body "$action")"
  icon="$(cli_notify_icon "$namespace" "$percent")"
  transient="true"

  cli_notify_send_request \
    "$namespace" \
    "$action" \
    "$percent" \
    "$summary" \
    "$body" \
    "$icon" \
    "$transient"
}
