# bashly.sh agent contract

This repository is a simple Bashly source-edit workflow surface.

## Core rule

```txt
agent edits source
local CI validates
commit only when green
```

## Source boundary

- Edit Bashly config, source scripts, docs, or tests as needed for the task.
- Treat generated Bash as disposable output.
- Do not manually patch generated Bash as the durable fix.

## Validation boundary

The validation authority is the local CI/pre-commit job defined by `schema/bashly_workflow.cue`.

Expected CI order:

```txt
shellharden -> shfmt -> shellcheck source -> bashly generate -> report
```

Generated ShellCheck and Bats/ShellSpec tests are project extensions, not required by the root contract unless a project opts in.
