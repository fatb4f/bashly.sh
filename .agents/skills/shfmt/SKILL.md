---
name: shfmt
description: Use for Bash formatting/diff normalization after ACP-mediated edits. Prefer repo adapters or editor/LSP integration rather than prompt-level formatter reconstruction.
---

# shfmt

Use shfmt as a formatting and parse-normalization gate.

Default posture:

- `shfmt -d` for validation
- `shfmt -w` only on source files, never generated Bashly artifacts unless explicitly requested
