---
name: shellharden
description: Use when reviewing or hardening Bash quoting in source Bashly partials. Advisory by default; never transform generated artifacts unless explicitly requested.
---

# Shellharden

Shellharden is advisory by default.

Workflow:

1. Run non-mutating review first.
2. Apply transforms only to a narrow source file set.
3. Inspect diff.
4. Run syntax/static checks and CLI tests.

Do not transform code that intentionally relies on word splitting/globbing without an explicit decision.
