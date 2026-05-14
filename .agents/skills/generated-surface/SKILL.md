---
name: generated-surface
description: Use whenever generated Bashly scripts, completions, or artifacts are present. Enforces source-first edits and prevents accidental manual patching of generated files.
---

# Generated surface

Generated artifacts are not implementation authority.

Allowed by default:

- inspect generated output
- compare generated output after regeneration
- run generated output for smoke tests
- diagnose generator effects

Forbidden by default:

- manual patching generated scripts
- formatting generated scripts as source
- shellharden transforms on generated output
- treating generated output as the place to fix source bugs

Source-first repair path:

```txt
settings / bashly.yml / partials / tests
  -> bashly generate
  -> inspect diff
  -> validate
```
