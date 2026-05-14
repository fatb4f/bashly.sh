# Repo-local Codex home guidance

This `.codex/` directory is intended to be used as a repo-local Codex home:

```sh
CODEX_HOME="$PWD/.codex" codex
```

Repository policy still lives in root `AGENTS.md` and repo-scoped skills still live in `.agents/skills/`.

## Defaults

- Treat Agentic.nvim/ACP as the mandatory implementation adapter.
- Use this `.codex/` tree for frames, prompts, and local profile state.
- Do not store secrets in `.codex/`.
- Keep volatile logs/sessions ignored by Git.
