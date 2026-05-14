# ACP / Neovim contract

Agentic.nvim/ACP is the mandatory implementation path.

```txt
agent provider
  -> ACP
  -> Agentic.nvim
  -> Neovim buffers
  -> LSP diagnostics/symbols/references
  -> diff review
  -> file changes
```

Direct file patching is bypass-only.

Validation commands may run outside Neovim after edits.
