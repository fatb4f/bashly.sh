# Bash LSP through MCP

Bash language intelligence belongs to Neovim.
The ACP provider receives that language intelligence through the configured MCP
bridge.

## Contract

```txt
bash-language-server
  -> Neovim LSP client
  -> Neovim diagnostics/symbols/definitions/references
  -> MCP bridge
  -> ACP provider tools/context
  -> Agentic.nvim session
```

Agentic.nvim is the ACP/editor surface. It does not replace the LSP server and
it does not itself guarantee language intelligence.

## Required capabilities

For Bash and Bashly implementation work, the Neovim/MCP surface should expose:

- diagnostics
- definitions
- references
- symbols
- hover/context where available

## Usage pattern

```txt
open relevant Bash/Bashly file in Neovim
  -> ensure Bash LSP attaches
  -> inspect diagnostics/symbols as needed
  -> expose relevant LSP state through MCP
  -> add diagnostics or selection to Agentic.nvim context
  -> request implementation or repair
```

## Failure handling

If the Bash LSP or MCP bridge is unavailable:

1. report the missing component
2. avoid claiming LSP-backed analysis was performed
3. continue only with explicit reduced confidence or after the component is fixed

## Minimal MCP server shape

The exact provider configuration is local to the provider, but the shape is:

```json
{
  "mcpServers": {
    "nvim-lsp": {
      "command": "nvim-lsp-mcp",
      "args": []
    }
  }
}
```
