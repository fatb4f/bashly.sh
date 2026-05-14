---
name: acp-nvim-lsp-adapter
description: Mandatory implementation adapter for this repository. All code changes should be performed through Agentic.nvim/ACP so the agent operates with Neovim buffer context, LSP diagnostics, definitions, references, symbols, MCP-exposed tools, and editor-native diff review. Do not manually reconstruct shellcheck, shfmt, bash-language-server, or ad-hoc file-edit workflows in prompts.
---

# ACP Neovim LSP adapter

Agentic.nvim/ACP is the implementation boundary for this repository.

## Rule

All implementation changes must happen through Agentic.nvim/ACP.

The agent should not directly patch files through an external editor, raw shell redirection, ad-hoc Python rewrites, or manual text replacement unless explicitly instructed to bypass Agentic.nvim.

## Control path

```txt
Agentic.nvim
  -> ACP provider
  -> MCP tools
  -> nvim-lsp-mcp or equivalent bridge
  -> Neovim LSP clients
  -> diagnostics / symbols / references / definitions
  -> diff review
```

## Use for

- Bashly YAML/config edits
- Bash source partial edits
- diagnostic repair
- symbol/reference-aware changes
- refactors
- formatting/lint-driven fixes
- diff review before accepting edits

## After implementation

After Agentic.nvim/ACP-mediated edits:

1. inspect diff
2. regenerate Bashly artifacts
3. run syntax/static checks
4. run CLI contract tests
5. summarize source changes and generated effects
