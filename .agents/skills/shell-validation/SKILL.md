---
name: shell-validation
description: Use for shell syntax, formatting, and hardening validation such as shellcheck, shfmt, and shellharden. Owns validation commands and diagnostic interpretation, not Bashly domain semantics.
compatibility: Repo-local validation skill for shell implementation and test surfaces.
metadata:
  version: "1.0"
  owns:
    - shellcheck validation
    - shfmt validation
    - shellharden validation
    - shell syntax checks
---

# Shell validation

Use this skill when the task is about shell validation, formatting, or
hardening.

## Contract

Validation means checking shell code and reporting actionable diagnostics.

```txt
shell source
  -> syntax check
  -> shellcheck
  -> shfmt or shellharden as applicable
  -> validation result
```

This skill owns the validation surface, not Bashly semantics or test
authoring.

## Scope

Use this skill for:

- shell syntax validation
- shellcheck runs and diagnostic interpretation
- shfmt runs and formatting checks
- shellharden runs and quoting/hardening checks
- headless shell probes when they are purely validation-oriented

Do not use this skill to decide Bashly CLI intent, selector rules, or test
semantics.

## Validation posture

Prefer repository adapters when present:

```sh
./bin/check-requirements
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

Use direct tools only when an adapter is missing or insufficient.
