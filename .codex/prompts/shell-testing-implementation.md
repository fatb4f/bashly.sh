# Shell testing implementation prompt frame

Use this frame for Bats-core and ShellSpec implementation sessions.

## Required skills

For Bats-core work:

```txt
.agents/skills/agentic-nvim/SKILL.md
.agents/skills/bats-core/skill.md
```

For ShellSpec work:

```txt
.agents/skills/agentic-nvim/SKILL.md
.agents/skills/shellspec/skill.md
```

Use `.codex/prompts/bashly-implementation.md` when the primary work is Bashly
source, settings, generation, or generated-surface behavior.

## Frame

```txt
Task:
  <describe bounded test change>

Test surface:
  Bats-core | ShellSpec

Target behavior:
  <CLI contract or source-level shell behavior>

Creation channel:
  Agentic.nvim/ACP inside Neovim only

Required Neovim feedback:
  Bash LSP through MCP
  shellcheck diagnostics through Neovim
  shell formatting through Neovim
  Agentic.nvim diff/permission review

Bats-core owns:
  generated executable behavior
  argv/status/stdout/stderr contracts
  CLI fixtures
  PATH mocks
  Bats runner gates

ShellSpec owns:
  sourceable shell functions
  helpers and partial logic
  mocks/stubs
  parameterized examples
  ShellSpec runner gates

Required closeout:
  Agentic.nvim session/context used
  selected test skill
  tests added or changed
  fixture assumptions
  Bash LSP/MCP result
  shellcheck result
  shell formatting result
  Bats-core result, if applicable
  ShellSpec result, if applicable
  remaining failures
```

## Selection rule

Use Bats-core when the behavior is visible through an executable CLI.

Use ShellSpec when the behavior is sourceable shell logic, helper functions,
partials, mocks, or unit-like shell behavior.

## Operating loop

1. Identify the target behavior and choose Bats-core or ShellSpec.
2. Add the target source/test files and relevant diagnostics to Agentic.nvim
   context.
3. Create or modify test code through Agentic.nvim/ACP inside Neovim.
4. Apply Neovim-mediated shell formatting to changed shell test code.
5. Re-check Neovim diagnostics and shellcheck diagnostics.
6. Run the relevant Bats-core or ShellSpec gate.
7. Inspect final test diffs and report remaining failures.
