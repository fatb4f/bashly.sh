# shellcheck shell=bash
cli_notify_backlight_percent() {
  local current max device percent

  if [[ -n "${CLI_NOTIFY_BACKLIGHT_PERCENT:-}" ]]; then
    printf '%s\n' "$CLI_NOTIFY_BACKLIGHT_PERCENT"
    return 0
  fi

  if command -v brightnessctl > /dev/null 2>&1; then
    current="$(brightnessctl g 2> /dev/null || true)"
    max="$(brightnessctl m 2> /dev/null || true)"

    if [[ $current =~ ^[0-9]+$ && $max =~ ^[1-9][0-9]*$ ]]; then
      percent=$(((current * 100 + max / 2) / max))
      printf '%s\n' "$percent"
      return 0
    fi
  fi

  for device in /sys/class/backlight/*; do
    [[ -e "$device/brightness" && -e "$device/max_brightness" ]] || continue

    current="$(< "$device/brightness")"
    max="$(< "$device/max_brightness")"

    if [[ $current =~ ^[0-9]+$ && $max =~ ^[1-9][0-9]*$ ]]; then
      percent=$(((current * 100 + max / 2) / max))
      printf '%s\n' "$percent"
      return 0
    fi
  done

  printf '0\n'
}

cli_notify_sound_percent() {
  local volume percent

  if [[ -n "${CLI_NOTIFY_SOUND_PERCENT:-}" ]]; then
    printf '%s\n' "$CLI_NOTIFY_SOUND_PERCENT"
    return 0
  fi

  if command -v wpctl > /dev/null 2>&1; then
    volume="$(
      wpctl get-volume @DEFAULT_AUDIO_SINK@ 2> /dev/null | awk '
        match($0, /[0-9]+([.][0-9]+)?/) {
          print substr($0, RSTART, RLENGTH)
          exit
        }
      '
    )"

    if [[ -n "$volume" ]]; then
      percent="$(
        awk -v volume="$volume" 'BEGIN { printf "%d\n", (volume * 100) + 0.5 }'
      )"
      printf '%s\n' "$percent"
      return 0
    fi
  fi

  if command -v pactl > /dev/null 2>&1; then
    volume="$(
      pactl get-sink-volume @DEFAULT_SINK@ 2> /dev/null | awk '
        match($0, /[0-9]+%/) {
          print substr($0, RSTART, RLENGTH - 1)
          exit
        }
      '
    )"

    if [[ -n "$volume" ]]; then
      printf '%s\n' "$volume"
      return 0
    fi
  fi

  printf '0\n'
}
