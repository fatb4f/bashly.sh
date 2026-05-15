# Shell formatting through Neovim

Shell formatting is a Neovim-mediated feedback surface for changed shell code
when the optional Agentic integration is in use.

The concrete formatter is normally `shfmt`, exposed through the configured
Neovim formatting integration.

## Contract

```txt
changed shell buffer
  -> Neovim formatter
  -> shfmt-backed rewrite/check
  -> Agentic.nvim-visible buffer state when used
  -> final repository validation
```

## Use for

- Bashly source shell fragments
- partials/templates containing shell code
- shell helpers
- repository shell scripts

## Formatting loop

```txt
create or modify shell code through the chosen implementation channel
  -> format the buffer through Neovim
  -> review the diff
  -> re-run diagnostics
  -> run repository validation
```

## Generated output

Generated Bashly output is projection. It may be inspected for formatting
symptoms, but durable formatting fixes should usually be made in Bashly source,
partials, or templates.

## Reporting

Completion reports should state one of:

```txt
shell_format_result: formatted
shell_format_result: already formatted
shell_format_result: formatter unavailable: <missing tool/integration>
shell_format_result: not applicable: <reason>
```
