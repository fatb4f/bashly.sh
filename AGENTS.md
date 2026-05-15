# Repository contract

This repository is a Bashly-focused control surface for CLI projects, Bashly
source, generated shell artifacts, and shell test suites.

## Mandatory code creation channel

All implementation code creation MUST happen through Agentic.nvim/ACP inside
Neovim.

This applies to:

- Bashly source/config changes
- Bash source partials and helpers
- Bats-core tests
- ShellSpec specs
- repository scripts and adapters
- documentation changes that accompany implementation work

Direct shell patching is not an accepted implementation path.

Shell commands outside Neovim may be used only for sensing, projection, and
validation:

- repository inspection
- file discovery
- Bashly generation
- diagnostics collection
- test execution
- smoke checks
- final diff inspection

Do not ask an agent to manually reconstruct the Neovim feedback loop from
terminal output when the Agentic.nvim workflow can expose the relevant file,
selection, diagnostic, formatting, and MCP context directly.

## Required skills

For Bashly implementation work, use:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/bashly/SKILL.md`

For Bats-core test implementation work, use:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/bats-core/skill.md`

For ShellSpec implementation work, use:

- `.agents/skills/agentic-nvim/SKILL.md`
- `.agents/skills/shellspec/skill.md`

## Authority split

`agentic-nvim` owns the implementation channel:

- Agentic.nvim/ACP sessions
- Neovim file, buffer, selection, and diagnostic context
- Bash LSP through the MCP bridge
- shellcheck diagnostics through Neovim
- shell formatting through Neovim
- editor-native permission and diff review
- headless Neovim probes for load, diagnostics, formatting, and health checks

`bashly` owns Bashly domain correctness:

- Bashly project discovery
- Bashly settings
- `bashly.yml`
- source partials and templates
- Bashly generation
- generated-output boundaries

`bats-core` owns black-box CLI behavior tests:

- generated executable behavior
- argv/status/stdout/stderr contracts
- fixtures and PATH mocks
- Bats runner gates

`shellspec` owns source-level shell specs:

- sourceable shell functions
- helper libraries
- mocks/stubs
- parameterized shell behavior
- ShellSpec runner gates

## Bashly workflow

1. Resolve the active Bashly project root.
2. Inspect effective Bashly settings before assuming paths.
3. Define or preserve the CLI contract before changing implementation.
4. Open or restore an Agentic.nvim session in Neovim.
5. Add the smallest sufficient file, selection, diagnostic, or test context.
6. Use Bash LSP through MCP, shellcheck diagnostics, and shell formatting through
   Neovim while creating code.
7. Edit Bashly settings, `bashly.yml`, partials, templates, tests, or docs
   through Agentic.nvim/ACP.
8. Regenerate artifacts.
9. Run syntax/static checks, smoke checks, and test gates.
10. Inspect source, generated, and test diffs before summarizing.

## Bats-core and ShellSpec workflow

1. Select the correct test skill.
2. Use Bats-core for generated executable and CLI behavior contracts.
3. Use ShellSpec for sourceable shell functions, helpers, and partial logic.
4. Create or modify test code through Agentic.nvim/ACP inside Neovim.
5. Use Neovim diagnostics, shellcheck, and shell formatting for changed shell test
   code.
6. Run the relevant Bats-core or ShellSpec runner gate.
7. Report the command, result, fixture assumptions, and remaining failures.

## Generated-surface policy

Generated scripts are reproducible artifacts.

Do not manually patch generated Bashly output unless the task is explicitly
forensic or generated-artifact-only.

Generated output may be inspected, executed, diagnosed, compared, and used to
identify the Bashly source that must change.

## Headless Neovim boundary

Headless Neovim is allowed for health checks, plugin-load checks, API probes,
scripted diagnostic collection, formatting checks, and CI-style validation.

Headless Neovim is not the default code creation surface.

Implementation code creation still requires the Agentic.nvim/ACP workflow with
Neovim context and editor-native review.

## Offline reference policy

Prefer repository-local references before web lookup.

Use web lookup only when explicitly requested or when local references are
absent, stale, or insufficient.

## Validation posture

Prefer repo adapters under `bin/`:

```sh
./bin/check-requirements
./bin/bashly-generate <project-root>
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

If a command is missing, report the missing requirement rather than inventing a
replacement workflow.

## Completion report

Implementation summaries must include:

```txt
agentic_session:
context_added:
skills_used:
changed_source:
generated_artifacts:
bash_lsp_mcp_result:
shellcheck_result:
shell_format_result:
tests_run:
validation_run:
remaining_failures:
```
