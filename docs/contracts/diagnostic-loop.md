# Diagnostic Loop

The bridge should keep a short feedback loop:

1. project discovery
2. projection of Bashly/source facts
3. selector-addressed diagnostics
4. diagnostic gating and publication
5. headless Neovim mutation when required
6. regeneration and verification

## Diagnostic policy

- Prefer selector-addressed diagnostics when a selector is available.
- Include range information when the producer can provide it.
- Keep diagnostics structured enough for both humans and automation.
- Gate diagnostics separately from publication.
- Use the outer verification gate to report generated-surface failures.
- Optional consumers such as Agentic.nvim or `nvim-lsp-mcp` may observe the
  published diagnostics, but they are not required by the core contract.
