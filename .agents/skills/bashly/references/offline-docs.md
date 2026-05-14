# Offline docs

Prefer repository-local Bashly docs under `docs/` before web lookup.

Expected local reference roots may include:

```txt
docs/bashly-ref/
docs/Bashly/
docs/
```

Use local docs for Bashly syntax, settings, generation behavior, and examples.

Use web lookup only when local docs are missing, stale, insufficient, or when the user explicitly requests online verification.

When reference extraction becomes large, write a short summary to `.codex/frames/` rather than repeatedly loading long docs.
