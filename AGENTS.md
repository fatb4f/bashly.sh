# Repository contract

This repository is a Bashly-focused repo for CLI projects and Bashly tooling.

## Mandatory implementation adapter

All implementation edits should happen through Agentic.nvim/ACP.

Use the Neovim-native agent surface so edits have access to:

- live buffer context
- Neovim LSP diagnostics
- definitions
- references
- symbols
- MCP-exposed editor tools
- editor-native diff review

Do not instruct the agent to directly patch files, manually reconstruct shellcheck/shfmt/bash-language-server workflows, or bypass Agentic.nvim unless explicitly requested.

Validation commands may still run outside Neovim.

## Authority order

1. Bashly settings
2. Bashly YAML config
3. Bashly source partials
4. tests and examples
5. generated output
6. docs

## Bashly workflow

1. Resolve the active Bashly project root.
2. Inspect effective Bashly settings before assuming paths.
3. Define or preserve the CLI contract before changing implementation.
4. Edit settings, `bashly.yml`, partials, tests, or docs through Agentic.nvim/ACP.
5. Regenerate artifacts.
6. Run syntax/static checks.
7. Run CLI contract tests.
8. Summarize source changes and generated effects.

## Generated-surface policy

Generated scripts are reproducible artifacts.

Do not manually patch generated Bashly output unless the task is explicitly forensic or generated-artifact-only.

## Offline reference policy

Prefer local references under `docs/`.

Use web lookup only when explicitly requested or when local references under `docs/` are absent/insufficient.

## Validation posture

Prefer repo adapters under `bin/`:

```sh
./bin/check-requirements
./bin/bashly-generate <project-root>
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

If a command is missing, report the missing requirement rather than inventing a replacement workflow.
