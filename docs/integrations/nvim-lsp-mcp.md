# nvim-lsp-mcp Integration

`nvim-lsp-mcp` is an optional consumer of diagnostics and language state.

It can observe `vim.diagnostic` output published by the Bashly projector, but
it is not a bridge requirement.

The core bridge contracts remain selector projection, diagnostics, and
headless Neovim source authority.
