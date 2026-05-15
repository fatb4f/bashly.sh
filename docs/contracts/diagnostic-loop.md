# Diagnostic Loop

The bridge should keep a short feedback loop:

1. project discovery
2. projection of Bashly/source facts
3. selector-addressed diagnostics
4. headless Neovim mutation when required
5. regeneration and verification

## Diagnostic policy

- Prefer selector-addressed diagnostics when a selector is available.
- Include range information when the producer can provide it.
- Keep diagnostics structured enough for both humans and automation.
- Use the outer verification gate to report generated-surface failures.
