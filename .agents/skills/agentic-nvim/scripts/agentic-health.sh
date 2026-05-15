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

# Codex ACP is the repository's mandatory Agentic.nvim provider. Other ACP
# providers may exist locally, but they do not satisfy this repository contract.
need codex-acp

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
