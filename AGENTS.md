# Repository contract

This repository is a Bashly-focused control surface for CLI projects, Bashly
source, generated shell artifacts, and shell test suites.

## Canonical bridge docs

The selector bridge contract lives in:

- `docs/contracts/bashly-bridge.md`
- `docs/contracts/generated-surface.md`
- `docs/contracts/diagnostic-loop.md`

Those docs define the `bashly_project`, `bashly_apply_chunk`, and
`bashly_generate_verify` boundaries, the disposable nature of generated CLI
artifacts, and the rule that `src/*.sh` mutation happens through headless
Neovim.

## Core bridge authority

The Bashly bridge substrate is:

- Bashly
- headless Neovim
- Tree-sitter
- `vim.diagnostic`
- shellcheck / shfmt / shellharden validation
- MCP tool contracts

This applies to Bashly source/config changes, Bash source partials and
helpers, Bats-core tests, ShellSpec specs, repository scripts and adapters, and
implementation docs.

Optional consumers such as Agentic.nvim or an ACP provider are not part of the
core bridge authority.

Shell commands outside Neovim may be used only for sensing, projection, and
validation:

- repository inspection
- file discovery
- Bashly generation
- diagnostics collection
- test execution
- smoke checks
- final diff inspection

## Required skills

For Bashly implementation work, use:

- `.agents/skills/bashly-bridge/SKILL.md`
- `.agents/skills/bashly/SKILL.md`
- `.agents/skills/shell-validation/SKILL.md`

For Bats-core test implementation work, use:

- `.agents/skills/bashly-bridge/SKILL.md`
- `.agents/skills/bats-core/skill.md`
- `.agents/skills/shell-validation/SKILL.md`

For ShellSpec implementation work, use:

- `.agents/skills/bashly-bridge/SKILL.md`
- `.agents/skills/shellspec/skill.md`
- `.agents/skills/shell-validation/SKILL.md`

If an Agentic.nvim/ACP consumer is actually used, document it explicitly as an
optional integration rather than core authority.

## Validation posture

Prefer repo adapters under `bin/`:

```sh
./bin/check-requirements
./bin/bashly-generate <project-root>
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

If a command is missing, report the missing requirement rather than inventing a
replacement workflow.

## Completion report

Implementation summaries should use these fields:

```txt
skill_context:
execution_substrate:
context_added:
changed_source:
generated_artifacts:
bash_lsp_mcp_result:
diagnostic_feedback:
shellcheck_result:
shell_format_result:
tests_run:
validation_run:
remaining_failures:
```
