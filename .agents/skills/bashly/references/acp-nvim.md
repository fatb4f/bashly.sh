# Agentic.nvim and ACP

Agentic.nvim/ACP is the implementation adapter for this repository.

## Rule

Implementation edits should originate through Agentic.nvim/ACP unless the user explicitly requests a bypass.

Use the adapter to preserve:

- live Neovim buffer context
- LSP diagnostics
- definitions, references, and symbols
- MCP-exposed tools such as nvim-lsp-mcp
- editor-native diff review
- provider session continuity

## Boundary

ACP is the control channel. Agentic.nvim is the editor-native client. MCP exposes tools to the provider. Neovim LSP is the semantic sensor.

Do not turn shellcheck, shfmt, bash-language-server, or grep invocations into prompt-level reconstruction when the ACP/LSP path can provide the same context.

Validation may still run outside Neovim through repo adapters.
