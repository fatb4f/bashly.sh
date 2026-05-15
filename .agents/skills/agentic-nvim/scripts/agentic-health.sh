#!/usr/bin/env sh
set -eu

missing=0

need() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'found: %s -> %s\n' "$1" "$(command -v "$1")"
  else
    printf 'missing: %s\n' "$1"
    missing=1
  fi
}

need nvim

if command -v nvim >/dev/null 2>&1; then
  nvim --version | head -1
fi

# Preferred/known ACP providers. At least one provider must be available in the
# real development environment, but this script reports rather than guessing.
found_provider=0
for cmd in codex-acp claude-agent-acp gemini opencode cursor-agent; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'found provider: %s -> %s\n' "$cmd" "$(command -v "$cmd")"
    found_provider=1
  fi
done

if [ "$found_provider" -eq 0 ]; then
  printf 'missing: ACP provider command\n'
  missing=1
fi

# Neovim-mediated sensors. Exact integration is configured in Neovim, but the
# executables should resolve on the development host.
need bash-language-server
need shellcheck
need shfmt

if command -v nvim >/dev/null 2>&1; then
  nvim --headless +'lua local ok, a = pcall(require, "agentic"); if not ok then error(a) end' +qa 2>/tmp/agentic-health.nvim.err \
    && printf 'agentic.nvim load: ok\n' \
    || { printf 'agentic.nvim load: failed\n'; cat /tmp/agentic-health.nvim.err; missing=1; }
fi

exit "$missing"
