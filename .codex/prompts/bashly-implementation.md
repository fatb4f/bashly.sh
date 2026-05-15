# Bashly implementation prompt frame

Use this frame for Bashly source, settings, generation, and generated-surface
implementation sessions.

## Required skills

```txt
.agents/skills/agentic-nvim/SKILL.md
.agents/skills/bashly/SKILL.md
```

Use `.codex/prompts/shell-testing-implementation.md` when the primary work is
Bats-core or ShellSpec test implementation.

## Frame

```txt
Task:
  <describe bounded Bashly change>

Active Bashly project:
  <path>

Creation channel:
  Agentic.nvim/ACP inside Neovim only

Required Neovim feedback:
  Bash LSP through MCP
  shellcheck diagnostics through Neovim
  shell formatting through Neovim
  Agentic.nvim diff/permission review

Bashly source surfaces allowed:
  bashly-settings.yml / settings.yml
  bashly.yml
  src/
  partials/
  templates/
  docs tied to the implementation

Generated surfaces:
  inspect/regenerate/execute/diagnose/compare only
  do not patch generated Bashly output as the durable fix

Testing handoff:
  use Bats-core for generated CLI behavior
  use ShellSpec for sourceable shell helpers/functions

Required closeout:
  Agentic.nvim session/context used
  Bashly project/settings discovered
  source diff summary
  generated artifact summary
  Bash LSP/MCP result
  shellcheck result
  shell formatting result
  generation result
  smoke/test result
  remaining failures
```

## Operating loop

1. Resolve the active Bashly project root.
2. Inspect effective Bashly settings before assuming paths.
3. Add the relevant Bashly source, generated-output symptom, diagnostics, or
   selection to Agentic.nvim context.
4. Create or modify Bashly source through Agentic.nvim/ACP.
5. Apply Neovim-mediated shell formatting to changed shell source.
6. Re-check Neovim diagnostics and shellcheck diagnostics.
7. Regenerate Bashly output.
8. Run repo validation adapters.
9. Inspect final source and generated diffs.
