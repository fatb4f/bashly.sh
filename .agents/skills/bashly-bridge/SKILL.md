---
name: bashly-bridge
description: Use for the core Bashly selector bridge contract: project discovery, selector projection, diagnostic gating, generated-surface policy, and headless Neovim as the source mutation authority.
compatibility: Repo-local bridge skill for Bashly selector graphs, projection joins, and diagnostics.
metadata:
  version: "1.0"
  owns:
    - selector graph
    - Bashly projection
    - diagnostic gate
    - generated-surface rule
    - headless Neovim source authority
---

# Bashly bridge

Use this skill for the repository's core bridge contract.

## Contract

The bridge is substrate-native:

```txt
Bashly YAML
  -> public command intent

Tree-sitter
  -> live source structure

headless Neovim
  -> mutation authority and diagnostics surface

vim.diagnostic
  -> projector feedback bus

MCP tool contracts
  -> structured consumers of projection and apply APIs
```

Core bridge APIs:

- `bashly_project`
- `bashly_apply_chunk`
- `bashly_generate_verify`

Generated Bash is disposable. The durable source of truth is Bashly source plus
bridge projections and diagnostics.

## Scope

Use this skill for:

- selector graph definitions
- projection shapes and joins
- diagnostics and gate logic
- generated-surface policy
- source authority boundaries
- headless Neovim write-path rules
- optional MCP consumer contracts

Do not use this skill to replace Bashly domain semantics. Bashly settings and
`bashly.yml` remain under the Bashly skill.

## Optional integrations

Agentic.nvim, ACP providers, and `nvim-lsp-mcp` are optional consumers of the
bridge. They are not the bridge substrate.

If one of those integrations is used, document it as an execution substrate
choice, not as core authority.

## References

- `docs/contracts/bashly-bridge.md`
- `docs/contracts/generated-surface.md`
- `docs/contracts/diagnostic-loop.md`
- `docs/integrations/agentic-nvim.md`
- `docs/integrations/acp.md`
- `docs/integrations/nvim-lsp-mcp.md`
