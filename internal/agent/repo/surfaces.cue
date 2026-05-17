package repo

import "github.com/fatb4f/bashly.sh/internal/agent/base"

surfaces: {
	future_frames: [
		{
			path: ".codex/frames/repo-frame.md"
			source: "internal/agent/codex/frames.cue"
			edit_policy: "never-hand-edit"
			kind: "frame"
		},
		{
			path: ".codex/frames/skills.md"
			source: "internal/agent/codex/frames.cue"
			edit_policy: "never-hand-edit"
			kind: "frame"
		},
		{
			path: ".codex/frames/workflow.md"
			source: "internal/agent/codex/frames.cue"
			edit_policy: "never-hand-edit"
			kind: "frame"
		},
	]

	future_indexes: [
		{
			path: ".codex/generated/skill-index.json"
			source: "internal/agent/codex/indexes.cue"
			edit_policy: "never-hand-edit"
			kind: "index"
		},
	]

	future_rules: [
		{
			path: ".codex/rules/default.rules"
			source: "internal/agent/codex/rules.cue"
			edit_policy: "never-hand-edit"
			kind: "rule"
		},
	]
}

generated_surfaces: [...base.#GeneratedSurface] & [
	for s in surfaces.future_frames {
		s
	},
	for s in surfaces.future_indexes {
		s
	},
	for s in surfaces.future_rules {
		s
	},
]
