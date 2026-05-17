package agent

import (
	"github.com/fatb4f/bashly.sh/internal/agent/codex"
	"github.com/fatb4f/bashly.sh/internal/agent/repo"
)

agentEntry: {
	moduleRoot: "cue.mod/"
	authority: "internal/agent/repo"
	projections: "internal/agent/codex"
	staticCheck: "scripts/check-agent-static.sh"
	discovery: repo.authority_contract
	repoBoot: repo.boot_contract
	repoFrame: codex.repo_frame
	skillFrame: codex.skill_frame
	workflowFrame: codex.workflow_frame
}
