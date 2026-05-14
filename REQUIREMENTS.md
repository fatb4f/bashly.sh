# Requirements

## Host tools

Required:

- `git`
- `bash` 5.2+
- `ruby`
- `bashly`
- `codex`
- `nvim` 0.10+
- `node` / `npm`
- `bash-language-server`
- `shellcheck`
- `shfmt`

Recommended:

- `shellharden`
- `bats` or `shellspec`
- `yq`
- `cue`
- `sem`
- `fd`
- `ripgrep`

Agentic path:

- Agentic.nvim installed in Neovim
- ACP-compatible provider configured
- MCP bridge for Neovim LSP, such as `nvim-lsp-mcp`, when provider-side LSP tool access is desired

## Repository requirements

- All implementation edits go through Agentic.nvim/ACP unless explicitly bypassed.
- Direct shell commands are allowed for validation, generation, inspection, and packaging.
- Bashly generated outputs are artifacts, not primary source.
- Source authority is Bashly settings, `bashly.yml`, partials, tests, and docs.
- Offline references should live under `refs/` and be preferred over web lookup.

## Minimal validation loop

```sh
./bin/check-requirements
./bin/bashly-generate projects/example-cli
./bin/bashly-check projects/example-cli
./bin/bashly-smoke projects/example-cli
```

## Tool ownership

```txt
Agentic.nvim / ACP = implementation adapter
Codex              = planning/policy/workflow agent
Neovim LSP         = diagnostics/symbols/references sensor
Bashly             = CLI generator
ShellCheck         = static analyzer
shfmt              = formatter/diff normalizer
Shellharden        = review-gated quoting hardener
CLI tests          = behavioral authority
```
