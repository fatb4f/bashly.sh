# Repo contract frame

```txt
repo kind: Bashly CLI/tooling repo
implementation adapter: Agentic.nvim/ACP mandatory
semantic sensor: Neovim LSP exposed through ACP/MCP path
source authority: Bashly settings + bashly.yml + partials
generated authority: reproducible artifact only
validation authority: syntax + static analysis + CLI smoke/contract tests
```

## Project discovery

A Bashly project root is a directory containing one of:

- `bashly.yml`
- `src/bashly.yml`
- `bashly-settings.yml`
- `settings.yml`

Always inspect settings before assuming source or target paths.
