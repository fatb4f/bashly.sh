# Sourceability contract

## Goal

ShellSpec works best when the file under test can be loaded without triggering
unwanted runtime behavior.

A sourceable shell file may define:

- functions
- constants
- readonly defaults
- lightweight variable initialization

It should not automatically:

- parse user argv
- call external services
- mutate the user's real home directory
- start background services
- exit the parent shell

## Execution guard

For files that can be sourced or executed, use a guard appropriate to the repo's
shell target.

Common Bash shape:

```bash
main() {
  :
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
```

Do not force this exact guard into POSIX-only projects.

## Bashly source partials

For Bashly projects, prefer testing source partials and helper files before
generated output.

```txt
src/lib/*.sh       -> ShellSpec
src/*.sh helpers   -> ShellSpec when sourceable
bin/generated-cli  -> Bats
```

Do not patch generated Bashly output to make ShellSpec happy. Repair the source
partial or helper instead.
