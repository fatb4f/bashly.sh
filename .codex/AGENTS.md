# Repo-local Codex home guidance

Root policy lives in `AGENTS.md`.
Repo-scoped skills live in `.agents/skills/`.
Prompt frames live in `.codex/prompts/`.

## Mandatory workflow

Treat Agentic.nvim/ACP inside Neovim as the mandatory code creation channel for
implementation work.

Do not create implementation patches directly from a generic shell workflow.
Shell commands may still inspect, generate, lint, test, smoke, and review diffs.

## Prompt routing

Use `.codex/prompts/bashly-implementation.md` for Bashly source, settings,
partials, templates, generation, and generated-surface work.

Use `.codex/prompts/shell-testing-implementation.md` for Bats-core and
ShellSpec implementation work.

Both prompt frames require the `agentic-nvim` skill.

## Skill routing

Bashly implementation:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/bashly/SKILL.md`

Bats-core implementation:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/bats-core/skill.md`

ShellSpec implementation:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/shellspec/skill.md`

## Defaults

- Use this `.codex/` tree for frames, prompts, and local profile state.
- Keep prompt frames small and task-shaped.
- Do not store secrets in `.codex/`.
- Keep volatile logs, sessions, and transcripts ignored by Git.
