set shell := ["bash", "-euo", "pipefail", "-c"]

agentctl := "go run github.com/fatb4f/agent-sdk/cmd/agentctl@latest"

default:
  just --list

agent-vet:
  {{agentctl}} vet --project-root .

agent-generate:
  {{agentctl}} generate --project-root .

agent-check-generated:
  {{agentctl}} check-generated --project-root .

agent-doctor:
  {{agentctl}} doctor --project-root .

source-check:
  {{agentctl}} check-generated --project-root .

source-write:
  {{agentctl}} generate --project-root .

static: agent-vet agent-check-generated
