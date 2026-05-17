set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  just --list

agent-entry:
  cue eval ./agent-sdk/profiles/bash-cli -e workflow

discovery-frame:
  cue export ./agent-sdk/codex -e discoveryFrame --out text

static:
  agent-sdk/scripts/check-agent-static.sh

agent-generate:
  agent-sdk/scripts/generate.sh

agent-check-generated:
  agent-sdk/scripts/check-agent-generated.sh

source-check:
  scripts/pre-commit-ci.sh --mode=check --project-root .

source-write:
  scripts/pre-commit-ci.sh --mode=write --project-root .
