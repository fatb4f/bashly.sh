# Workflow

Source of truth: `internal/agent/repo/workflow.cue`

| Phase | Tool | Mode | Mutates Source | After | Blocks On |
|---|---|---|---:|---|---|
| `inspect` | bashly | check | false |  |  |
| `edit_source` | bashly | write | true | inspect | generated_bash_edited |
| `format_shellharden` | shell-validation | write | true | edit_source | shellharden_failed |
| `format_shfmt` | shell-validation | write | true | format_shellharden | shfmt_failed |
| `lint_source_shellcheck` | shell-validation | check | false | format_shfmt | shellcheck_source_failed |
| `generate_bashly` | bashly | generate | false | lint_source_shellcheck | bashly_generate_failed |
| `report` | report | check | false | generate_bashly |  |

Deferred: lint_generated, bats-core, shellspec

generate_bashly.command: `bashly generate`
generate_bashly.env.BASHLY_FORMATTER: `none`
generate_bashly.source_mutation_guard: `true`
generate_bashly.blocks_on: `bashly_generate_failed`

Validation order: shellharden -> shfmt -> shellcheck source -> bashly generate with Bashly formatting disabled -> report.
