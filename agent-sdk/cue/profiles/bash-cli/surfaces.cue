package bashcli

import "github.com/fatb4f/agent-sdk/cue/base"

surfaces: {
	generation_targets: [...base.#GenerationTarget] & [
		{
			name: "repo-frame"
			kind: "frame"
			input: "generationData.repoFrame"
			template: "internal/agent/templates/repo-frame.md.tmpl"
			output: ".codex/frames/repo-frame.md"
			format: "markdown"
			materializer: "gomplate"
			edit_policy: "never-hand-edit"
		},
		{
			name: "skills-frame"
			kind: "frame"
			input: "generationData.skillFrame"
			template: "internal/agent/templates/skills.md.tmpl"
			output: ".codex/frames/skills.md"
			format: "markdown"
			materializer: "gomplate"
			edit_policy: "never-hand-edit"
		},
		{
			name: "workflow-frame"
			kind: "frame"
			input: "generationData.workflowFrame"
			template: "internal/agent/templates/workflow.md.tmpl"
			output: ".codex/frames/workflow.md"
			format: "markdown"
			materializer: "gomplate"
			edit_policy: "never-hand-edit"
		},
		{
			name: "skill-index"
			kind: "index"
			input: "skillIndex"
			output: ".codex/generated/skill-index.json"
			format: "json"
			materializer: "cue-export"
			edit_policy: "never-hand-edit"
		},
		{
			name: "surface-index"
			kind: "index"
			input: "surfaceIndex"
			output: ".codex/generated/surface-index.json"
			format: "json"
			materializer: "cue-export"
			edit_policy: "never-hand-edit"
		},
		{
			name: "default-rules"
			kind: "rule"
			input: "generationData.commandRules"
			template: "internal/agent/templates/default.rules.tmpl"
			output: ".codex/rules/default.rules"
			format: "text"
			materializer: "gomplate"
			edit_policy: "never-hand-edit"
		},
	]

	future_frames: [
		{
			path: ".codex/frames/repo-frame.md"
			source: "internal/agent/templates/repo-frame.md.tmpl"
			edit_policy: "never-hand-edit"
			kind: "frame"
		},
		{
			path: ".codex/frames/skills.md"
			source: "internal/agent/templates/skills.md.tmpl"
			edit_policy: "never-hand-edit"
			kind: "frame"
		},
		{
			path: ".codex/frames/workflow.md"
			source: "internal/agent/templates/workflow.md.tmpl"
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
		{
			path: ".codex/generated/surface-index.json"
			source: "internal/agent/codex/indexes.cue"
			edit_policy: "never-hand-edit"
			kind: "index"
		},
	]

	future_rules: [
		{
			path: ".codex/rules/default.rules"
			source: "internal/agent/templates/default.rules.tmpl"
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
