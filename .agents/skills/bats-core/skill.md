---
name: bats-core
description: Use for Bats test generation and maintenance for shell CLIs, especially Bashly-generated command behavior. Owns black-box CLI contract tests, fixtures, mocks, assertions, runner gates, and Bats-specific troubleshooting.
compatibility: Repo-local agent skill for Bats core, bats-support, bats-assert, and bats-file based shell test suites.
metadata:
  version: "1.0"
  owns:
    - Bats test generation
    - CLI contract tests
    - Bats fixtures and PATH mocks
    - Bats runner gates
  delegates:
    - Bashly schema and generated CLI source to the bashly skill
    - Shell source-level unit specs to the shellspec skill
    - shellcheck, shell formatting, and shell validation to the shell-validation skill
---

# Bats core

Use this skill when work requires Bats tests for shell commands, generated CLIs,
Bashly command behavior, or black-box executable contracts.

## Contract

Bats owns executable behavior tests.

```txt
command under test
  -> argv/env/filesystem fixture
  -> Bats run
  -> explicit status/stdout/stderr assertions
  -> isolated cleanup
  -> repo runner gate
```

Prefer Bats when the tested surface is a command, subcommand, generated Bashly
binary, usage text, argument parser, exit code, stdout/stderr contract, or CLI
integration behavior.

Use ShellSpec instead when the target is a sourceable function or helper library
that benefits from direct function calls, mocks, or parameterized examples.

## Activation

Use this skill for:

- generated Bashly CLI contract tests
- shell command smoke tests
- subcommand routing checks
- `--help` / usage contract checks
- invalid argv and missing input behavior
- stdout/stderr/exit-status verification
- filesystem fixture behavior
- PATH-based dependency mocks for command tests
- Bats test maintenance and failure diagnosis

Do not use this skill to design Bashly YAML, edit generated Bashly output, run
shellcheck/formatting, or replace ShellSpec for source-level function tests.

## Required test shape

Every generated Bats test should make the contract legible:

```txt
setup fixture
  -> run command
  -> assert status
  -> assert output and/or stderr
  -> assert files when relevant
```

Use `run` for commands whose status/output must be inspected.
Use `$BATS_TEST_TMPDIR` for per-test filesystem state.
Use PATH-prepended stub executables for external command mocks.
Use helper libraries when available:

- `bats-support`
- `bats-assert`
- `bats-file`

If helper libraries are unavailable, use plain Bats assertions and keep the
fallback obvious.

## Bashly CLI contract default

For Bashly-generated CLIs, default Bats coverage to:

- root `--help`
- command/subcommand `--help`
- required argument missing
- invalid flag or argument
- one success path
- one failure path
- stdout/stderr distinction when user-visible
- exit status for every scenario

Use `assets/bashly-cli-contract.bats` as the starter template.

## Runner gate

Prefer the repository runner when present. Otherwise use direct Bats commands.

```sh
bats test
bats tests
bats --jobs 4 tests
bats --formatter tap tests
bats --formatter junit tests > test-results/bats.xml
```

Do not model Bats parallel execution as `--parallel`; use `--jobs`.

## References

- [CLI contract patterns](references/cli-contract.md)
- [Fixtures and mocks](references/fixtures-mocks.md)
- [Assertions and output](references/assertions-output.md)
- [Runner gates and troubleshooting](references/runner-gates.md)
