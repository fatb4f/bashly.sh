# Bashly Bridge Contract

This repository treats Bashly as the authority for public CLI intent and keeps
generated shell artifacts disposable.

## Core invariants

- `bashly.yml` defines command intent.
- Tree-sitter describes live source structure.
- `argc` contributes optional inline argv facts.
- `bash-ast` contributes Bash-native parse and structure proof.
- Headless Neovim owns source mutation and diagnostics.
- `vim.diagnostic` is the projector feedback bus.
- MCP tool contracts are structured consumers of the bridge.
- Agentic.nvim / ACP / `nvim-lsp-mcp` are optional consumers, not authority.
- Codex edits selectors, not coordinates.

## Primary tool boundaries

- `bashly_project(workspace)` reads project settings, inspects source, and
  returns a structured projection.
- `bashly_apply_chunk(request)` resolves selectors and mutates source through
  headless Neovim only.
- `bashly_generate_verify(workspace)` runs the outer generated-surface gate.

## Generated surface rule

Generated Bashly output is reproducible and disposable.

- Do not treat generated CLI scripts as canonical edit targets.
- Do not patch generated scripts as source authority when the Bashly source can
  be changed instead.
- Use generated output for verification, smoke checks, and downstream contract
  tests.

## Source mutation rule

All edits to `src/*.sh` flow through headless Neovim.

The bridge may collect facts from Tree-sitter, Bash LSP, `argc`, and
`bash-ast`, but it does not write files directly from Python or MCP code.

Optional consumers such as Agentic.nvim, ACP, and `nvim-lsp-mcp` may observe
or drive the bridge, but they are not required by the core contract.
