if [[ -n "${args[--run-locker]}" ]]; then
  # Avoid duplicate hyprlock instances.
  if pgrep -xu "$USER" hyprlock >/dev/null 2>&1; then
    exit 0
  fi

  systemctl --user start locked-session-halt.timer || true

  hyprlock_config="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"
  
  if [[ -f "$hyprlock_config" ]]; then
    hyprlock \
      --config "$hyprlock_config" \
      --immediate-render \
      --no-fade-in
  else
    hyprlock \
      --immediate-render \
      --no-fade-in
  fi

  # session-unlock owns unlock policy and cleanup.
  "$HOME/.local/bin/session-unlock" || true
else
  # Default or --request
  sid="${XDG_SESSION_ID:-}"

  if [[ -n "$sid" ]]; then
    loginctl lock-session "$sid"
  else
    loginctl lock-session
  fi
fi
