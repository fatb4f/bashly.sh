package agent

import (
	"github.com/fatb4f/bashly.sh/internal/agent/codex"
)

agentEntry: {
	moduleRoot: "cue.mod/"
	discoveryFrame: codex.discovery_frame
	repoFrame: codex.repo_frame
	skillFrame: codex.skill_frame
	workflowFrame: codex.workflow_frame
}
