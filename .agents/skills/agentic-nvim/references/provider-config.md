# Provider configuration

Agentic.nvim talks to ACP-compatible providers.
The provider is the agent runtime; Agentic.nvim is the Neovim client surface.

## Provider entry shape

A provider entry normally defines:

```lua
{
  provider = "codex-acp",
  acp_providers = {
    ["codex-acp"] = {
      name = "Codex ACP",
      command = "codex-acp",
      args = {},
      env = {},
    },
  },
}
```

## Repo expectation

This repository requires `codex-acp` as the Agentic.nvim ACP provider. Other ACP
providers may be useful elsewhere, but they do not satisfy this repository
contract unless the user explicitly requests a provider bypass.

Required Codex ACP provider behavior:

- accepts Agentic.nvim ACP sessions
- can receive file/selection/diagnostic context
- can request file edits through the editor-mediated permission/diff flow
- can use configured MCP tools when available

## Environment

Provider authentication and configuration should reuse the provider's normal CLI
configuration. Do not hardcode secrets in repo-local skill files.

## Failure handling

If the provider command does not resolve or cannot initialize:

1. report the provider failure
2. do not silently fall back to direct shell patching
3. fix provider configuration or ask for an explicit bypass
