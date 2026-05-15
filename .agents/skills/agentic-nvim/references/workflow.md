# Agentic.nvim workflow

Agentic.nvim is the Neovim-native ACP client used as the repository code
creation channel.

## Runtime graph

```txt
user keymap / Lua API
  -> require("agentic").open/toggle/add_context/restore/switch
  -> SessionRegistry resolves the current tabpage session
  -> SessionManager owns session state and ChatWidget
  -> AgentInstance returns the shared ACP provider process
  -> ACPClient sends JSON-RPC over stdio
  -> provider streams session updates and tool calls
  -> UI renders messages, diffs, permissions, diagnostics, todos
  -> file edits trigger reload/checktime and hooks
```

## Process/session model

```txt
ACP provider process: one per provider
ACP session:          one per Neovim tabpage
SessionManager:       one per Neovim tabpage
ChatWidget:           one per Neovim tabpage
```

Do not add module-level mutable state for per-session behavior.
Per-session state belongs behind the tabpage/session manager boundary.

## Public API boundary

Prefer Agentic.nvim public APIs instead of reaching into internal modules.
Expected public operations include:

- open / close / toggle
- rotate layout
- add current file
- add selection
- add explicit files
- add selection or current file
- add current-line diagnostics
- add buffer diagnostics
- create or restore sessions
- switch provider
- stop generation

## Implementation loop

```txt
open target repo in Neovim
  -> open or restore Agentic.nvim session
  -> add smallest useful file/selection/diagnostic context
  -> request implementation through ACP provider
  -> review permission prompts and diffs
  -> apply Neovim diagnostics/formatting feedback
  -> run repository generation/validation commands
  -> inspect final diff
```

## Completion rule

Agentic.nvim mediates code creation. It does not prove correctness by itself.
Correctness requires the target repository validation surface.
