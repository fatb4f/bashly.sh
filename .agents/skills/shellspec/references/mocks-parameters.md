# ShellSpec mocks and parameters

## Mock external commands

Use ShellSpec mocks when a function calls an external command and the behavior
under test depends on the command result.

```sh
Describe 'current_branch'
  Include ./src/lib/git.sh

  Mock git
    echo main
  End

  It 'returns the branch name'
    When call current_branch
    The output should eq 'main'
  End
End
```

Keep mocks local to the example or describe block that needs them.

## Parameters

Use `Parameters` to compress repeated function examples without hiding the
contract.

```sh
Describe 'truthy'
  Include ./src/lib/bool.sh

  Parameters
    'yes' 0
    'true' 0
    'no' 1
  End

  It "classifies $1"
    When call truthy "$1"
    The status should eq "$2"
  End
End
```

Do not over-parameterize when named examples would communicate failures more
clearly.

## State and variables

Reset global variables in `BeforeEach` or keep them local to the function under
test. Avoid test order dependencies.

```sh
BeforeEach 'reset_state'

reset_state() {
  export TOOL_STATE=''
}
```
