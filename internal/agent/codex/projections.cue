package codex

import (
	"strings"

	"github.com/fatb4f/bashly.sh/internal/agent/repo"
)

repoFrame: repo.repo_boot_projection.value

skillIndex: repo.skillIndex

skillFrame: strings.Join([
	"# Project-local skills",
	"",
	"Source of truth: `internal/agent/repo/skills.cue`",
	"",
	"| Skill | Status | Path | Purpose |",
	"|---|---:|---|---|",
	for s in repo.skillIndex {
		"| \(s.id) | \(s.status) | `\(s.path)` | \(s.purpose) |"
	},
	"",
	"Discovery rule: answer inventory questions from this frame or `skill-index.json` before opening `SKILL.md` files.",
], "\n")

workflowFrame: strings.Join([
	"# Workflow",
	"",
	"Source of truth: `internal/agent/repo/workflow.cue`",
	"",
	"| Phase | Tool | Mode | Mutates Source | After | Blocks On |",
	"|---|---|---|---:|---|---|",
	for p in repo.workflow.phases {
		"| \(p.id) | \(p.tool) | \(p.mode) | \(p.mutates_source) | \(p.after) | \(p.blocks_on) |"
	},
	"",
	"Validation order is source-edit first, then validation, then later generation.",
], "\n")

defaultRules: strings.Join([
	for r in repo.command_rules {
		"""
		\(r.kind)_rule(
		    pattern = "\(strings.Join(r.pattern, " "))",
		    decision = "\(r.decision)",
		    justification = "\(r.justification)",
		)
		"""
	},
], "\n\n")
