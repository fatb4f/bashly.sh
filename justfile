set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  just --list

agent-vet:
  go run github.com/fatb4f/agent-sdk/cmd/agentctl vet --project-root .

agent-generate:
  go run github.com/fatb4f/agent-sdk/cmd/agentctl generate --project-root .

agent-check-generated:
  go run github.com/fatb4f/agent-sdk/cmd/agentctl check-generated --project-root .

agent-doctor:
  go run github.com/fatb4f/agent-sdk/cmd/agentctl doctor --project-root .

source-check:
  scripts/pre-commit-ci.sh --mode=check --project-root .

source-write:
  scripts/pre-commit-ci.sh --mode=write --project-root .
