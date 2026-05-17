# Repo-local discovery order

Source of truth: `internal/agent/repo/repo.cue`

## Repository

- Name: `bashly.sh`
- Module: `github.com/fatb4f/bashly.sh`

## Authority contract

```txt
CUE is authority.
Skills are procedural manuals.
Generated surfaces come later.
Use CUE projections before filesystem crawling once available.
```

## Discovery contract

```txt
## Repo-local discovery order

1. Read Codex-facing projections.
2. Read the skill index for inventory questions.
3. Read the workflow projection for validation and mutation policy.
4. Open `SKILL.md` only after selecting a relevant skill.
5. Use repo search only when generated projections lack the requested fact.
```
