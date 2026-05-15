# Headless Neovim boundary

Headless Neovim is a probe and validation surface. It is not the default code
creation surface.

## Contract

```txt
interactive Neovim + Agentic.nvim
  -> code creation, context handoff, permission review, diff review

headless Neovim
  -> load checks, API checks, diagnostic probes, formatting probes, CI checks
```

Use headless Neovim to prove that the editor substrate works. Do not use it to
replace the Agentic.nvim implementation loop.

## Accepted headless uses

- Agentic.nvim plugin load check
- public API presence check
- configured provider resolution check
- Bash LSP/MCP bridge probe
- shellcheck diagnostic probe
- shell formatter probe
- scripted validation before or after implementation
- CI-style health checks

## Not accepted as code creation

Do not use headless Neovim to bypass the required implementation channel.

Forbidden as the durable creation path:

- direct file rewriting from headless scripts
- direct patch application from headless scripts
- generating implementation code without Agentic.nvim context APIs
- accepting provider edits without editor-native diff or permission review

## Example probes

Plugin load check:

```sh
nvim --headless +'lua local ok, err = pcall(require, "agentic"); if not ok then error(err) end' +qa
```

API check:

```sh
nvim --headless -l .agents/skills/agentic-nvim/scripts/nvim-agentic-check.lua
```

Health check:

```sh
.agents/skills/agentic-nvim/scripts/agentic-health.sh
```

## Reporting

Completion reports should distinguish interactive creation from headless probes:

```txt
agentic_session: interactive session used for code creation
headless_probe_result: load/API/diagnostic/format probes passed or unavailable
```
