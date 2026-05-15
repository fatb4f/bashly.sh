# Provider configuration

Agentic.nvim can talk to ACP-compatible providers.
The provider is the agent runtime; Agentic.nvim is the Neovim client surface
for that optional integration.

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

This repository documents `codex-acp` as one optional Agentic.nvim ACP
provider example. Other ACP providers may be useful elsewhere, but they are
integration choices rather than core bridge requirements.

Optional Codex ACP provider behavior:

- accepts Agentic.nvim ACP sessions when used
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
