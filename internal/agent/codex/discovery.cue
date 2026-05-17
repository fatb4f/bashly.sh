package codex

import (
	"strings"

	"github.com/fatb4f/bashly.sh/internal/agent/repo"
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
