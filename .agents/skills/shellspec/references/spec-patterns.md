# ShellSpec patterns

## Basic structure

```sh
Describe 'subject'
  Context 'condition'
    It 'does behavior'
      When call function_name arg
      The status should be success
      The output should eq 'expected'
    End
  End
End
```

Use `Describe` for the unit under test, `Context` for state or condition, and
`It` for the expected behavior.

## `When call`

Use `When call` for functions loaded into the current shell by `Include` or
`Source`.

```sh
Describe 'slugify'
  Include ./src/lib/text.sh

  It 'replaces spaces with hyphens'
    When call slugify 'hello world'
    The output should eq 'hello-world'
  End
End
```

## `When run`

Use `When run` for process behavior.

```sh
It 'runs a command'
  When run ./bin/tool --help
  The status should be success
  The output should include 'Usage:'
End
```

Prefer Bats for broad CLI behavior. Keep ShellSpec `When run` for cases where
staying inside the ShellSpec suite is more valuable than a black-box Bats test.

## Assertions

Common assertion surfaces:

```sh
The status should be success
The status should be failure
The output should eq 'value'
The output should include 'text'
The stderr should include 'error'
The variable name should eq 'value'
The path file should be file
```

Assert the smallest surface that proves the behavior.
