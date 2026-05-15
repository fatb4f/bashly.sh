# bashly.sh agent contract

## Purpose

This repository is a Codex/agent workflow surface for safe Bashly source editing.

The active model is intentionally simple:

```txt
agent edits source
local CI validates
CUE defines the workflow gate
skills provide local operating guidance
```

## Source authority

Use Bashly configuration and source scripts as the durable implementation surface:

- `bashly.yml` / `src/bashly.yml` / Bashly settings files define CLI intent.
- `src/*.sh` files are editable Bash implementation surfaces.
- generated Bashly output is disposable and reproducible.

Do not manually patch generated Bashly output as the durable fix.

## Validation authority

The pre-commit/local CI workflow is the validation authority.

Required order:

```txt
shellharden
shfmt
shellcheck source
bashly generate
CI report
```

`lint_generated` is currently deferred. Bats and ShellSpec are deferred unless a task explicitly activates them.

## Optional frontage

ACP, MCP, Neovim, LSP, and editor integrations are optional frontage. They are not required for the source-edit workflow.
