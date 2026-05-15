---
name: shellspec
description: Use for ShellSpec test generation and maintenance for sourceable shell functions, helper libraries, mocks, parameters, and unit-level behavior. Owns ShellSpec specs, sourceability contracts, mocks, examples, runner gates, and failure diagnosis.
compatibility: Repo-local agent skill for ShellSpec-based shell unit and component tests.
metadata:
  version: "1.0"
  owns:
    - ShellSpec spec generation
    - sourceable shell function tests
    - ShellSpec mocks and parameters
    - ShellSpec runner gates
  delegates:
    - generated CLI behavior tests to the bats-core skill
    - Bashly schema and generated CLI source to the bashly skill
    - shellcheck, shell formatting, LSP, and Neovim execution to the agentic-nvim skill
---

# ShellSpec

Use this skill when work requires source-level shell tests for functions,
helpers, libraries, or command implementation units that can be loaded without
executing the whole CLI.

## Contract

ShellSpec owns sourceable shell behavior tests.

```txt
sourceable shell file
  -> Describe / Context / It
  -> When call or When run
  -> explicit status/output/variable/file assertions
  -> mocks or parameters when needed
  -> repo runner gate
```

Prefer ShellSpec when the target is a function, helper, source partial,
normalizer, parser, or branch-heavy shell unit.

Use Bats instead when the target is a generated executable, command-line parser,
usage text, argv contract, or black-box CLI behavior.

## Activation

Use this skill for:

- shell helper unit tests
- Bashly source partial logic tests
- parser or normalizer function tests
- function-level mocks/stubs
- parameterized examples
- sourceability repairs for testable shell files
- ShellSpec runner maintenance and failure diagnosis

Do not use this skill to test generated CLI behavior that is better expressed as
argv/status/stdout/stderr. Use the Bats skill for that surface.

## Required spec shape

Prefer direct function calls for unit behavior:

```sh
Describe 'helper_function'
  Include ./src/lib/helper.sh

  It 'normalizes input'
    When call helper_function 'input'
    The status should be success
    The output should eq 'expected'
  End
End
```

Use `When run` or `When run script` only when process-level behavior is the
thing being tested.

## Sourceability boundary

Shell files tested by ShellSpec should be safely sourceable.

A sourceable file should avoid doing work at import time except definitions,
constants, and guarded initialization. If a file must support direct execution,
use an execution guard.

Do not add project-specific logger or framework assumptions unless the target
repo already uses them.

## Runner gate

Prefer the repository runner when present. Otherwise use direct ShellSpec
commands.

```sh
shellspec
shellspec --syntax-check
shellspec --jobs 4
shellspec --format documentation
```

Use `shellspec --init` only when bootstrapping a new suite.

## References

- [Spec patterns](references/spec-patterns.md)
- [Sourceability](references/sourceability.md)
- [Mocks and parameters](references/mocks-parameters.md)
- [Runner gates and troubleshooting](references/runner-gates.md)
