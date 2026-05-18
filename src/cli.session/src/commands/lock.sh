if [[ -n "${args["--run-locker"]:-}" ]]; then
  session_locker
else
  session_lock_request
fi
