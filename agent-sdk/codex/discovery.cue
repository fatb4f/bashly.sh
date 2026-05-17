package codex

import (
	"strings"

	repo "github.com/fatb4f/bashly.sh/agent-sdk/profiles/bash-cli:bashcli"
)

discoveryFrame: strings.Join([
	"# Agent entrypoint",
	"",
	"This repository is CUE-authored.",
	"",
	"Start with `cue.mod/`.",
	"",
	"Do not treat `AGENTS.md` as policy authority.",
	"",
	"Authority graph: `internal/agent/repo`",
	"Projection graph: `internal/agent/codex`",
	"Static check: `scripts/check-agent-static.sh`",
	"",
	"Discovery contract:",
	repo.authority_contract,
	repo.boot_contract,
], "\n")
