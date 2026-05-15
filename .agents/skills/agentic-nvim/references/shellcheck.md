# shellcheck through Neovim

shellcheck is a diagnostic source for shell implementation work when the
optional Agentic integration is in use.

The accepted path is Neovim-mediated diagnostics, not an isolated manual lint
loop that the Agentic.nvim session cannot see.

## Contract

```txt
shellcheck
  -> Neovim diagnostic integration
  -> buffer diagnostics
  -> Agentic.nvim context when used
  -> optional ACP repair prompt
  -> re-check diagnostics
```

## Use for

- quoting issues
- unsafe expansions
- unreachable or suspicious branches
- command-substitution issues
- unassigned variables
- shell portability warnings where relevant
- generated-shell syntax/semantic warnings when applicable

## Required repair loop

```txt
open changed shell file in Neovim
  -> collect shellcheck diagnostics through Neovim
  -> add relevant diagnostics to the active implementation context
  -> ask provider for a bounded repair
  -> re-run shellcheck diagnostics through Neovim
```

## Generated output

Generated Bashly output may be diagnosed and inspected.
Do not treat generated output as the durable implementation surface unless the
repository or user explicitly says the task is generated-artifact-only.

When generated output has shellcheck diagnostics, prefer repairing the Bashly
source that generated it.

## Reporting

Completion reports should state one of:

```txt
shellcheck_result: clean
shellcheck_result: warnings remain: <summary>
shellcheck_result: unavailable: <missing tool/integration>
shellcheck_result: not applicable: <reason>
```
