# shellcheck shell=bash
notify_osd() {
  local kind value body title icon key

  kind="${1:?kind required}"
  value="${2:?value required}"
  body="${3:-}"

  case "$kind" in
  volume)
    title="Volume"
    icon="audio-volume-high-symbolic"
    key="volume"
    if [[ -z "$body" ]]; then
      body="${value}%"
    fi
    ;;
  brightness)
    title="Brightness"
    icon="display-brightness-symbolic"
    key="brightness"
    if [[ -z "$body" ]]; then
      body="${value}%"
    fi
    ;;
  mute)
    title="Volume"
    icon="audio-volume-muted-symbolic"
    key="volume"
    value=0
    if [[ -z "$body" ]]; then
      body="Muted"
    fi
    ;;
  *)
    printf 'notify_osd: unknown kind: %s\n' "$kind" >&2
    return 64
    ;;
  esac

  if ! command -v notify-send >/dev/null 2>&1; then
    printf 'notify_osd: missing required command: %s\n' "notify-send" >&2
    return 127
  fi

  notify-send \
    --app-name="System" \
    --urgency=low \
    --expire-time=1200 \
    --icon="$icon" \
    --hint=string:x-canonical-private-synchronous:"$key" \
    --hint=int:value:"$value" \
    "$title" \
    "$body"
}
