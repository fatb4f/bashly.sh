package codex

import (
	"strings"

	"github.com/fatb4f/bashly.sh/internal/agent/repo"
)

repo_frame: repoFrame
skill_frame: skillFrame
workflow_frame: workflowFrame

repoFrame: repo.repo_boot_projection.value
generateBashly: repo.workflow.phases[5]

skillFrame: strings.Join([
	"# Project-local skills",
	"",
	"Source of truth: `internal/agent/repo/skills.cue`",
	"Inventory projection: `internal/agent/codex/indexes.cue`",
	"",
	"| Skill | Status | Path | Purpose |",
	"|---|---:|---|---|",
	for s in skillIndex {
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
	"Deferred: \(strings.Join(repo.workflow.deferred, ", "))",
	"",
	"generate_bashly.command: `\(strings.Join(generateBashly.command, " "))`",
	"generate_bashly.env.BASHLY_FORMATTER: `\(generateBashly.env.BASHLY_FORMATTER)`",
	"generate_bashly.source_mutation_guard: `\(generateBashly.source_mutation_guard)`",
	"generate_bashly.blocks_on: `\(generateBashly.blocks_on)`",
	"",
	"Validation order is shellharden -> shfmt -> shellcheck source -> bashly generate with Bashly formatting disabled -> report.",
], "\n")
