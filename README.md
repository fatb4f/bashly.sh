# bashly-acp-codex-base

Base repository scaffold for Bashly projects driven through Codex + Agentic.nvim/ACP.

## Contract

```txt
Bashly config/settings = CLI authority
Bash source partials   = implementation authority
generated scripts      = reproducible artifacts
Agentic.nvim / ACP     = mandatory implementation adapter
Neovim LSP / MCP       = semantic sensor bridge
Codex skills           = reusable workflow contracts
```

## Start

```sh
git init
./bin/check-requirements
CODEX_HOME="$PWD/.codex" codex
```

## Layout

```txt
AGENTS.md                root policy loaded by Codex
REQUIREMENTS.md          host/tool requirements and validation contract
.codex/                  repo-local Codex home, frames, prompts
.agents/skills/          repo-scoped Codex skills
bin/                     deterministic repo commands
refs/                    local/offline reference clones
projects/                Bashly project roots
nvim/agentic/            Agentic.nvim / ACP integration notes
```

## Intended use

Place one or more Bashly project roots under `projects/`, or replace `projects/example-cli` with the first real project.

Implementation edits should originate from Agentic.nvim/ACP. Shell commands in `bin/` are validation/control adapters, not the primary edit path.
