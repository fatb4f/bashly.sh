set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  just --list

agent-entry:
  cue eval ./internal/agent -e agentEntry

discovery-frame:
  cue export ./internal/agent/codex -e discoveryFrame --out text

static:
  scripts/check-agent-static.sh

source-check:
  scripts/pre-commit-ci.sh --mode=check --project-root .

source-write:
  scripts/pre-commit-ci.sh --mode=write --project-root .
