# Repo-local Codex guidance

Root policy lives in `AGENTS.md`.

Repo-local skills live in `.agents/skills/`. Each skill directory owns:

```txt
SKILL.md   # loadable skill manifest with valid YAML front matter
AGENTS.md  # skill-local operating instructions
skill.cue  # small capability/gate contract
```

The root workflow contract lives in `schema/bashly_workflow.cue`.

## Operating model

```txt
Codex edits source.
Skills provide local guidance.
Pre-commit/local CI validates.
CUE defines the gate contract.
```

## Local workflow

Use the Bashly skill for source/config workflow guidance and the shell-validation skill for the pre-commit CI order.

Do not route ordinary source edits through a mandatory editor, ACP, MCP, or remote runtime.

## Prompt policy

Central prompt files are intentionally not used. Skill-local `AGENTS.md` files own the prompt/context for each skill.

## Defaults

- Do not store secrets in `.codex/`.
- Keep volatile logs, sessions, and transcripts ignored by Git.
- Keep repo-local guidance small; put skill-specific details in skill directories.
