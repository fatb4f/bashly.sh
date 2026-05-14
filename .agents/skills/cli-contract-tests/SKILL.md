---
name: cli-contract-tests
description: Use when validating Bashly CLI behavior: help output, success path, missing arguments, invalid flags, exit codes, and generated executable behavior.
---

# CLI contract tests

Behavioral checks should cover:

- root `--help`
- command `--help`
- success path
- missing required arg
- invalid flag
- expected exit code
- expected stdout/stderr split

Use Bats or ShellSpec when available. Use `./bin/bashly-smoke` as the minimal base smoke adapter.
