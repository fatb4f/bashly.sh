# Context policy

Agentic.nvim context should be precise, current, and editor-native.

## Preferred context sources

Use Agentic.nvim context APIs for:

- current file
- visual selection
- explicit file list
- current-line diagnostics
- buffer diagnostics
- provider slash commands
- restored provider session history

## Selection rules

```txt
local bug
  -> visual selection + current-line diagnostics

whole-file repair
  -> current file + buffer diagnostics

multi-file behavior change
  -> explicit file list + related diagnostics

generator/domain change
  -> Bashly source files + generated-output inspection only when needed

continuation
  -> restore the existing Agentic session before adding new context
```

## Diagnostic handoff

When a repair depends on diagnostics, add diagnostics to context before asking
for code changes.

Use this ordering:

```txt
collect diagnostics in Neovim
  -> add current-line or buffer diagnostics to Agentic.nvim
  -> ask provider for a bounded repair
  -> re-run diagnostics
```

## Avoid

- large manual context dumps
- unrelated generated files
- stale diagnostics copied from old terminal output
- replacing LSP/MCP context with manual summaries when editor context is available
- asking the provider to infer project shape without adding the responsible files
