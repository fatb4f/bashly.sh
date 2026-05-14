---
name: bashly
description: Use for Bashly CLI implementation work: resolving project/settings boundaries, editing bashly.yml and source partials, implementing Bats or ShellSpec tests, preserving generated-artifact discipline, using Agentic.nvim/ACP for edits, regenerating artifacts, and validating CLI behavior with shellcheck, shfmt, shellharden, syntax checks, and smoke/contract tests.
compatibility: Designed for Codex/Agentic.nvim workflows in Bashly repositories with local docs under docs/ and optional Bash tooling installed.
metadata:
  version: "1.0"
  repo: "fatb4f/bashly.sh"
---

# Bashly

This skill is the single repository-local Bashly implementation skill.

Use it for any task that changes or validates a Bashly CLI project, including command contract changes, implementation partials, tests, generated artifacts, diagnostics, formatting, quoting hardening, or offline Bashly reference lookup.

## Hard contract

Implementation means **code plus tests**.

A Bashly implementation task is incomplete until it addresses:

1. effective Bashly project/settings boundaries
2. CLI contract in `bashly.yml` or the configured Bashly config path
3. Bash source partials/helpers when behavior changes
4. Bats and/or ShellSpec tests for the changed behavior
5. generated artifacts after regeneration
6. syntax/static/format/behavior validation
7. final diff review

## Mandatory adapter

All implementation edits should happen through Agentic.nvim/ACP unless the user explicitly requests a bypass.

Agentic.nvim/ACP is the implementation boundary because it gives the agent Neovim buffer state, LSP diagnostics, definitions, references, symbols, MCP-exposed tools, and editor-native diff review.

Validation commands may run outside Neovim, but file-changing implementation should originate through the ACP/Neovim path.

See [ACP adapter reference](references/ACP_NVIM.md) when editor/LSP/MCP details matter.

## Authority order

1. Bashly settings: `bashly-settings.yml`, `settings.yml`, or local equivalent
2. Bashly config: usually `bashly.yml` or `src/bashly.yml`
3. source partials/helpers under the effective source directory
4. tests and examples
5. generated scripts/completions/artifacts
6. docs

Generated artifacts are reproducible outputs, not implementation authority.

## Resolve the active project first

Before editing, identify and record:

```txt
project_root:
settings_file:
source_dir:
config_path:
target_dir:
generated_outputs:
test_dirs:
```

Do not assume Bashly defaults until settings are inspected.

Use `scripts/inspect-project.py` when a deterministic summary helps.

Detailed boundary rules: [Bashly workflow reference](references/BASHLY_WORKFLOW.md).

## Default implementation workflow

1. Resolve the active Bashly project root.
2. Inspect settings and effective source/config/target paths.
3. Read the existing CLI contract and tests before changing behavior.
4. Define the target user-visible CLI behavior.
5. Implement source/config changes through Agentic.nvim/ACP.
6. Add or update tests in the same slice.
7. Regenerate Bashly artifacts.
8. Run validation.
9. Inspect generated and source diffs.
10. Summarize changed contract, changed source, tests, and generated effects.

## Test policy

Prefer **Bats** for generated CLI behavior:

- root `--help`
- command `--help`
- success path
- missing required input
- invalid flag/arg
- stdout/stderr split
- exit status

Prefer **ShellSpec** for source-level shell logic:

- helper functions
- implementation functions
- branch behavior
- mocks/stubs
- edge cases awkward to exercise through the generated CLI

If CLI behavior changes, add/update a CLI contract test.

If reusable shell logic changes, add/update a source-level ShellSpec test when practical.

If no test is added, explicitly state whether existing coverage already proves the change or why the change is not testable.

Templates and examples:

- [Bats/ShellSpec testing reference](references/TESTING.md)
- `assets/bats-cli-contract.bats`
- `assets/shellspec-helper-spec.sh`

## Generated-surface policy

Allowed by default:

- inspect generated output
- compare generated output after regeneration
- execute generated output for smoke/contract tests
- diagnose generator effects

Forbidden by default:

- manual patching generated Bashly scripts
- formatting generated scripts as source
- Shellharden transforms on generated output
- fixing source bugs in generated output

Source-first repair path:

```txt
settings / bashly.yml / partials / tests
  -> bashly generate
  -> inspect diff
  -> validate
```

See [generated surface reference](references/GENERATED_SURFACE.md).

## YAML contract rules

Treat the Bashly YAML config as the CLI contract authority.

Preserve or intentionally update:

- command names and aliases
- help text and examples
- required args
- flags and environment variables
- default values
- exit behavior documented by tests/examples
- generated command structure

Prefer schema/CUE/yq validation when available.

## Validation posture

Prefer repo adapters when present:

```sh
./bin/check-requirements
./bin/bashly-generate <project-root>
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

If adapters are missing, report the missing command and use local project conventions. Do not invent a new permanent workflow without user approval.

Use these primitive gates as applicable:

```sh
bash -n <source-or-generated-script>
shellcheck <source-or-generated-script>
shfmt -d <source-files>
shellharden --check <source-files>
bats <bats-tests>
shellspec <shellspec-tests>
```

Detailed validation rules: [validation reference](references/VALIDATION.md).

## ShellCheck, shfmt, and Shellharden

- ShellCheck is a static diagnostics gate.
- shfmt is a parse/format normalization gate.
- Shellharden is an advisory quoting hardener by default.

Apply mutating format/hardening only to source files unless the user explicitly requests generated-artifact work.

Always inspect the diff after mutating formatter/hardener commands.

## Offline reference policy

Prefer repository-local docs under `docs/` before web lookup.

Use web lookup only when the local docs are missing, stale, or insufficient, or when the user explicitly asks for online verification.

Reference lookup details: [offline docs reference](references/OFFLINE_DOCS.md).

## Completion criteria

For implementation tasks, final reporting should include:

```txt
project_root:
changed_contract:
changed_source:
tests_added_or_updated:
generated_artifacts:
validation_run:
remaining_risks:
```

A source-only change with no tests is incomplete unless explicitly justified.
