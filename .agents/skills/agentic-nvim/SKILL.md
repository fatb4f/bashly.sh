---
name: agentic-nvim
description: Optional integration reference for using Agentic.nvim with this repository's Bashly bridge. It is not the bridge substrate or default authority path.
compatibility: Optional integration documentation for Agentic.nvim/ACP consumers of the Bashly bridge.
metadata:
  version: "1.1"
  owns:
    - optional Agentic.nvim integration notes
    - optional ACP consumer guidance
    - optional Neovim context handoff examples
---

# Agentic.nvim

Agentic.nvim is an optional consumer of the Bashly bridge.

Use this skill when documenting or validating an Agentic.nvim-based integration
with the bridge.

## Contract

Implementation code creation for the core bridge flows through Bashly,
headless Neovim, Tree-sitter, and the repository scripts.

```txt
Neovim
  -> Agentic.nvim public API
  -> ACP provider session
  -> provider-generated edits
  -> Neovim diagnostics and formatting
  -> Agentic.nvim permission/diff review
  -> repository validation
```

Agentic.nvim is the editor/client surface when that integration is chosen.
The ACP provider is one possible transport/runtime.
Neovim provides buffers, files, selections, diagnostics, formatting, windows,
and diff review for that optional integration path.

Bash language intelligence is provided by Neovim LSP and exposed to the ACP
provider through the configured MCP bridge.

## Activation

Use this skill only when the task is specifically about Agentic.nvim / ACP
integration documentation or optional editor workflow validation.

Do not use this skill as the authority for Bashly domain semantics, Bats-core
test semantics, or ShellSpec test semantics. Those belong to the relevant domain
skills.

## Code creation boundary

The core bridge does not require Agentic.nvim/ACP.

Allowed outside Agentic.nvim:

- repository inspection
- file discovery
- diagnostic command execution
- formatting command execution when invoked by Neovim tooling
- generation commands
- validation commands
- final diff inspection

These are sensing, projection, and validation operations. They are not the code
creation channel for the core bridge.

## Required Neovim feedback surfaces

For optional Agentic.nvim integrations, the session may use these
Neovim-mediated feedback surfaces:

- Bash LSP diagnostics through MCP
- shellcheck diagnostics surfaced in Neovim
- shell formatting surfaced in Neovim

Relevant diagnostics should be added to the Agentic.nvim session context before
asking the provider to repair code.

Changed shell code should be formatted through the configured Neovim formatter
before final validation.

## Headless Neovim boundary

Headless Neovim is allowed for health checks, scripted validation,
plugin-load checks, Agentic.nvim API probes, diagnostic extraction, formatting
checks, and CI-style probes.

Headless Neovim is not the default code creation surface.

Headless Neovim is the core bridge validation surface. If Agentic.nvim is used
as a consumer, headless Neovim can support that optional workflow by proving
loadability, diagnostics, formatting, or configuration state.

Accepted headless uses:

- Agentic.nvim load checks
- public API presence checks
- Bash LSP/MCP probes
- shellcheck diagnostic probes
- shell formatter probes
- scripted validation before or after interactive Agentic.nvim work

Not accepted as the core bridge creation path:

- direct file patching from headless scripts
- bypassing Agentic.nvim context APIs
- bypassing permission/diff review

See [headless Neovim](references/headless.md).

## Context policy

Use Agentic.nvim context APIs only when that optional integration is in play.

Prefer the smallest sufficient context:

- current file for whole-file changes
- visual selection for scoped edits
- explicit file list for multi-file changes
- current-line diagnostics for local repairs
- buffer diagnostics for file-level repairs
- restored provider session for continuing prior work

Avoid dumping unrelated files, generated artifacts, or stale command output into
the session.

See [context](references/context.md).

## Provider/session model

One ACP provider process may serve multiple Agentic sessions.
Agentic keeps one session per Neovim tabpage.
Do not model the provider process, ACP session, tabpage, and chat widget as the
same thing.

See [workflow](references/workflow.md) and [provider config](references/provider-config.md).

## Bash LSP through MCP

Agentic.nvim does not itself provide Bash LSP.

Use the configured MCP bridge to expose Neovim LSP state to the ACP provider
when that optional integration is chosen.

See [LSP/MCP](references/lsp-mcp.md).

## shellcheck

shellcheck is a required diagnostic source for shell implementation work when
the optional Agentic integration is being exercised.

See [shellcheck](references/shellcheck.md).

## shell formatting

Shell formatting is a Neovim-mediated formatting surface for optional
Agentic integrations.

See [shell formatting](references/shellfmt.md).

## Diff and permission boundary

If Agentic.nvim is being used, provider edits must pass through its
editor-native permission and diff-review flow when approval is requested.

Do not treat provider edits as accepted until the editor diff has been reviewed
and the relevant buffers have been reloaded or checked.

## Completion evidence

Implementation reports should include:

```txt
agentic_session:
context_added:
bash_lsp_mcp_result:
shellcheck_result:
shell_format_result:
headless_probe_result:
validation_run:
remaining_failures:
```

See [validation](references/validation.md).
