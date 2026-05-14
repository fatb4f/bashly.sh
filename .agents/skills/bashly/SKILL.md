---
name: bashly
description: Use for Bashly CLI implementation work: project/settings discovery, bashly.yml contract changes, Bash partial edits, Bats or ShellSpec tests, generated artifact regeneration, Agentic.nvim/ACP-mediated editing, and validation with Bash syntax, ShellCheck, shfmt, Shellharden, smoke tests, and CLI contract tests.
compatibility: Designed for Codex/Agentic.nvim workflows in Bashly repositories with local docs under docs/ and optional Bash tooling installed.
metadata:
  version: "1.1"
  repo: "fatb4f/bashly.sh"
---

# Bashly

This is the single repository-local Bashly implementation skill.

Use it for Bashly CLI work that changes or validates user-visible command behavior, Bash source partials, tests, generated artifacts, static diagnostics, formatting, quoting, or local Bashly documentation lookup.

## Contract

Bashly implementation means **code plus tests**.

A task is incomplete until it has addressed the relevant source/config change, test coverage, regeneration, validation, and final diff review.

Authority order:

1. Bashly settings
2. Bashly YAML config, usually `bashly.yml` or `src/bashly.yml`
3. Bash source partials/helpers
4. tests and examples
5. generated scripts/completions/artifacts
6. docs

Generated artifacts are reproducible outputs, not implementation authority.

## Mandatory implementation adapter

All implementation edits should happen through Agentic.nvim/ACP unless the user explicitly requests a bypass.

Validation commands may run outside Neovim, but file-changing implementation should originate through the ACP/Neovim path.

See [Agentic.nvim and ACP](references/acp-nvim.md) for the editor/LSP/MCP boundary.

## Workflow

1. Resolve the active Bashly project root and effective settings.
2. Read the existing CLI contract and tests before changing behavior.
3. Define or preserve the target user-visible CLI behavior.
4. Edit settings, Bashly YAML, source partials, tests, or docs through Agentic.nvim/ACP.
5. Regenerate Bashly artifacts.
6. Run syntax, static, format, hardening, smoke, and contract checks as applicable.
7. Inspect source, test, and generated diffs.
8. Summarize contract changes, source changes, test changes, generated effects, validation, and remaining risk.

For project discovery details, use `scripts/inspect-project.py` and [Bashly workflow](references/workflow.md).

## Testing policy

If CLI behavior changes, add or update a CLI contract test.

Use Bats for generated CLI behavior. Use ShellSpec for source-level shell logic.

If no test is added, explicitly state whether existing tests already cover the change or why the change is not testable.

See [testing](references/testing.md). Use templates from `assets/bats-cli-contract.bats` and `assets/shellspec-helper-spec.sh` when bootstrapping coverage.

## Generated surface

Allowed by default: inspect, compare, execute, and diagnose generated output.

Forbidden by default: manually patch, format-as-source, or Shellharden-transform generated Bashly output.

See [generated surface](references/generated-surface.md).

## Validation

Prefer repo adapters when present:

```sh
./bin/check-requirements
./bin/bashly-generate <project-root>
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

Use primitive tools only when adapters are missing or insufficient.

See [validation](references/validation.md) and [shell tools](references/shell-tools.md).

## Offline docs

Prefer repository-local docs under `docs/` before web lookup.

Use web lookup only when local docs are missing, stale, insufficient, or the user explicitly asks for online verification.

See [offline docs](references/offline-docs.md).

## Completion report

For implementation tasks, report:

```txt
project_root:
changed_contract:
changed_source:
tests_added_or_updated:
generated_artifacts:
validation_run:
remaining_risks:
```
