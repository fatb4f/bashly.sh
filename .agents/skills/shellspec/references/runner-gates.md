# ShellSpec runner gates and troubleshooting

## Commands

Typical local gates:

```sh
shellspec
shellspec --syntax-check
shellspec --jobs 4
shellspec --format documentation
```

Use `shellspec --init` only to create a new ShellSpec scaffold.

## Parallel execution

Use `--jobs` only when specs are isolated. Shared globals, fixed temp files,
fixed ports, and global mocks can make parallel specs flaky.

## Common failures

| Symptom | Likely cause | Repair |
|---|---|---|
| spec exits during Include | file executes at source time | add execution guard or split library code |
| function not found | wrong Include path | resolve from spec working directory |
| mock not used | function calls absolute command | inject command or avoid absolute path where possible |
| examples affect each other | global state leak | reset in BeforeEach/AfterEach |
| suite is hard to read | overused Parameters | split into named examples |

## Debugging

Use ShellSpec's normal failure output first. Add `Dump` only while diagnosing and
remove noisy dumps before finalizing unless the repo intentionally keeps them.
