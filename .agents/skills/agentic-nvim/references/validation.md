# Validation boundary

Agentic.nvim is one optional code creation channel. It is not the final
validation authority.

## What this skill validates

This skill validates that implementation work used:

- Agentic.nvim/ACP as an optional code creation path
- Neovim context APIs for file/selection/diagnostic handoff
- Bash LSP through MCP when Bash language intelligence is available
- shellcheck diagnostics surfaced through Neovim
- shell formatting surfaced through Neovim
- editor-native diff/permission review
- headless Neovim probes for load, API, diagnostics, and formatting when used

## What this skill does not validate

This skill does not define:

- Bashly source semantics
- Bashly generation correctness
- generated artifact authority
- project-specific command behavior
- repository-specific test policy

Those belong to the relevant domain skills and repository adapters.

## Minimum completion evidence

```txt
agentic_session: <new/restored/session id or description or "not used">
context_added: <files/selections/diagnostics>
bash_lsp_mcp_result: <clean/warnings/unavailable/not applicable>
shellcheck_result: <clean/warnings/unavailable/not applicable>
shell_format_result: <formatted/already formatted/unavailable/not applicable>
headless_probe_result: <passed/unavailable/not applicable>
validation_run: <repo commands and results>
remaining_failures: <none or summary>
```

## Refusal to mark complete

Do not mark an implementation complete if:

- edits were created outside the chosen implementation channel without explicit bypass
- relevant diagnostics were ignored
- shell formatting was skipped for changed shell code
- provider diffs were not reviewed
- repository validation was not run or its failure was hidden
