---
name: shellcheck
description: Use for Bash static analysis after Agentic.nvim/ACP implementation edits or during validation. Prefer repo adapters instead of manually reconstructing shellcheck commands in prompts.
---

# ShellCheck

ShellCheck is a validation primitive, not the implementation adapter.

Preferred repo command:

```sh
./bin/bashly-check <project-root>
```

Use direct `shellcheck` only when the repo adapter is insufficient.
