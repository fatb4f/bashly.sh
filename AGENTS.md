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

## Mandatory code creation channel

All implementation code creation MUST happen through Agentic.nvim/ACP inside
Neovim.

This applies to Bashly source/config changes, Bash source partials and
helpers, Bats-core tests, ShellSpec specs, repository scripts and adapters, and
implementation docs.

Direct shell patching is not an accepted implementation path.

`approval_policy = "never"` in `.codex/config.toml` is intentional. Codex CLI
approval prompts are not the review boundary; Agentic.nvim editor-native
permission and diff review is the review boundary for implementation edits.

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

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/bashly/SKILL.md`

For Bats-core test implementation work, use:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/bats-core/skill.md`

For ShellSpec implementation work, use:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/shellspec/skill.md`

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
