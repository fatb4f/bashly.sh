# Validation

Prefer repo adapters when present:

```sh
./bin/check-requirements
./bin/bashly-generate <project-root>
./bin/bashly-check <project-root>
./bin/bashly-smoke <project-root>
```

## Primitive gates

Use these as applicable when adapters are missing or insufficient:

```sh
bash -n <script>
shellcheck <script>
shfmt -d <source-files>
shellharden --check <source-files>
bats <bats-tests>
shellspec <shellspec-tests>
```

## Validation report

Capture:

```txt
command:
result:
failures:
missing_requirements:
follow_up:
```

Do not silently replace a missing adapter with a newly invented permanent workflow. Report the gap.
