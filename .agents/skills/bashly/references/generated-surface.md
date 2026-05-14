# Generated surface

Generated Bashly artifacts are reproducible outputs, not implementation authority.

## Allowed by default

- inspect generated output
- compare generated output after regeneration
- execute generated output for smoke or contract tests
- diagnose generator effects

## Forbidden by default

- manually patch generated scripts
- format generated scripts as source
- Shellharden-transform generated scripts
- fix source bugs in generated output

## Repair path

```txt
settings / bashly.yml / source partials / tests
  -> bashly generate
  -> inspect diff
  -> validate
```

Only edit generated artifacts directly when the user explicitly asks for forensic or generated-artifact-only work.
