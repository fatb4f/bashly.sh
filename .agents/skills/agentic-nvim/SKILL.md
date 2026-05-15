---
name: agentic-nvim
description: Enforces Agentic.nvim as the repository code creation channel, using Neovim context, Bash LSP through MCP, shellcheck diagnostics, shell formatting, and editor-native diff/permission review.
compatibility: Designed for Codex/Agentic.nvim workflows where Bashly source is edited from Neovim and diagnostics/formatting are exposed through Neovim.
metadata:
  version: "1.0"
  owns:
    - Agentic.nvim/ACP code creation channel
    - Neovim context handoff
    - Bash LSP via MCP
    - shellcheck diagnostics via Neovim
    - shell formatting via Neovim
---

# Agentic.nvim

Agentic.nvim is the required code creation adapter.

Use this skill when implementation work must be created through Neovim rather
than a direct shell patching workflow.

## Contract

Implementation code creation flows through Agentic.nvim/ACP inside Neovim.

```txt
Neovim
  -> Agentic.nvim public API
  -> ACP provider session
  -> provider-generated edits
  -> Neovim diagnostics and formatting
  -> Agentic.nvim permission/diff review
  -> repository validation
```

Agentic.nvim is the editor/client surface.
The ACP provider is the agent runtime.
Neovim provides buffers, files, selections, diagnostics, formatting, windows,
and diff review.

Bash language intelligence is provided by Neovim LSP and exposed to the ACP
provider through the configured MCP bridge.

## Activation

Use this skill for:

- implementation edits
- refactors
- diagnostic repairs
- code generation
- context-rich Bash or Bashly changes
- editor-native review of provider edits

Do not use this skill as the authority for Bashly domain semantics. Bashly
source, generation, and generated-output rules belong to the Bashly skill.

## Code creation boundary

Implementation edits must originate through Agentic.nvim/ACP.

Allowed outside Agentic.nvim:

- repository inspection
- file discovery
- diagnostic command execution
- formatting command execution when invoked by Neovim tooling
- generation commands
- validation commands
- final diff inspection

These are sensing, projection, and validation operations. They are not the code
creation channel.

## Required Neovim feedback surfaces

For Bash and Bashly work, the Agentic.nvim session must use these Neovim-mediated
feedback surfaces:

- Bash LSP diagnostics through MCP
- shellcheck diagnostics surfaced in Neovim
- shell formatting surfaced in Neovim

Relevant diagnostics should be added to the Agentic.nvim session context before
asking the provider to repair code.

Changed shell code should be formatted through the configured Neovim formatter
before final validation.

## Context policy

Use Agentic.nvim context APIs instead of reconstructing context manually.

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

Use the configured MCP bridge to expose Neovim LSP state to the ACP provider.
Use Bash LSP for diagnostics, definitions, references, symbols, and local code
context where available.

See [LSP/MCP](references/lsp-mcp.md).

## shellcheck

shellcheck is a required diagnostic source for shell implementation work.

Use the Neovim-integrated shellcheck path so diagnostics are visible in buffers
and can be added to Agentic.nvim context.

See [shellcheck](references/shellcheck.md).

## shell formatting

Shell formatting is a required Neovim-mediated formatting surface.

Use the configured Neovim formatter, normally backed by `shfmt`, before final
validation.

See [shell formatting](references/shellfmt.md).

## Diff and permission boundary

Provider edits must pass through Agentic.nvim's editor-native permission and
diff-review flow when approval is requested.

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
validation_run:
remaining_failures:
```

See [validation](references/validation.md).
