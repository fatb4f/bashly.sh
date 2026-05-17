# Project-local skills

Source of truth: `internal/agent/repo/skills.cue`
Inventory projection: `internal/agent/codex/indexes.cue`

| Skill | Status | Path | Purpose | Load Policy |
|---|---:|---|---|---|
| `argc` | active | `.agents/skills/argc` | Argc annotation context and argv-guidance for shell source work. | on_select |
| `bash-ast` | active | `.agents/skills/bash-ast` | Bash AST evidence and structural inspection for shell source. | on_select |
| `bashly` | active | `.agents/skills/bashly` | Bashly source/config workflow and generated artifact boundary. | on_select |
| `bats-core` | deferred | `.agents/skills/bats-core` | Black-box Bash CLI behavior tests. | on_select |
| `shell-validation` | active | `.agents/skills/shell-validation` | Shell normalization, formatting, linting, and local CI gate interpretation. | on_select |
| `shellspec` | deferred | `.agents/skills/shellspec` | ShellSpec source-level Bash behavior tests. | on_select |
| `tree-sitter` | experimental | `.agents/skills/tree-sitter` | Structural parsing and grammar evidence for shell source. | on_select |

Discovery rule: answer inventory questions from this frame or `skill-index.json` before opening `SKILL.md` files.

Reference rule: treat skill `references/` trees as cold evidence unless the selected skill explicitly requires them.
