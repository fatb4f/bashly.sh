# Shell tools

## ShellCheck

ShellCheck is a static diagnostics gate. Prefer repo adapters or editor/LSP integration before direct command reconstruction.

## shfmt

shfmt is a parse and format normalization gate.

Use `shfmt -d` for validation. Use `shfmt -w` only on source files unless the user explicitly requests generated-artifact formatting.

## Shellharden

Shellharden is advisory by default.

Workflow:

1. Run non-mutating review first.
2. Apply transforms only to a narrow source file set.
3. Inspect diff.
4. Run syntax/static checks and CLI tests.

Do not transform code that intentionally relies on word splitting or globbing without an explicit decision.
