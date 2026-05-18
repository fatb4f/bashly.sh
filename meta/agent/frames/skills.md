# Skills Frame

answer inventory questions from this frame or `skill-index.json` before opening `SKILL.md` files.

| ID | Status | Path | Purpose |
|---|---|---|---|
| argc | active | `.agents/skills/argc` | Argc annotation context and argv-guidance for shell source work. |
| bash-ast | active | `.agents/skills/bash-ast` | Bash AST evidence and structural inspection for shell source. |
| bashly | active | `.agents/skills/bashly` | Bashly source/config workflow and generated artifact boundary. |
| bats-core | deferred | `.agents/skills/bats-core` | Black-box Bash CLI behavior tests. |
| shell-validation | active | `.agents/skills/shell-validation` | Shell normalization, formatting, linting, and local CI gate interpretation. |
| shellspec | deferred | `.agents/skills/shellspec` | ShellSpec source-level Bash behavior tests. |
| tree-sitter | experimental | `.agents/skills/tree-sitter` | Structural parsing and grammar evidence for shell source. |

Source of truth: `./cue/profiles/shell-library/skills.cue`
Inventory projection: `generated/skill-index.json`
