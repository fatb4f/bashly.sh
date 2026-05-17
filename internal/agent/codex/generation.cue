package codex

import repopkg "github.com/fatb4f/bashly.sh/internal/agent/repo"

generationData: {
	repo: {
		name: repopkg.name
		module: repopkg.module
		authority_contract: repopkg.authority_contract
		boot_contract: repopkg.boot_contract
	}

	repoFrame: repopkg.repo_boot_projection.value

	skillFrame: {
		source_of_truth: "internal/agent/repo/skills.cue"
		inventory_projection: "internal/agent/codex/indexes.cue"
		discovery_rule: "answer inventory questions from this frame or `skill-index.json` before opening `SKILL.md` files."
		rows: [
			for id in skillOrder {
				let s = repopkg.skills[id]
				{
					id: s.id
					status: s.status
					path: s.path
					purpose: s.purpose
					load_policy: s.load_policy
				}
			},
		]
	}

	workflowFrame: {
		source_of_truth: "internal/agent/repo/workflow.cue"
		validation_order: "shellharden -> shfmt -> shellcheck source -> bashly generate with Bashly formatting disabled -> report."
		deferred: repopkg.workflow.deferred
		phases: [
			{
				id: "inspect"
				tool: "bashly"
				mode: "check"
				mutates_source: false
				after: ""
				blocks_on: ""
			},
			{
				id: "edit_source"
				tool: "bashly"
				mode: "write"
				mutates_source: true
				after: "inspect"
				blocks_on: "generated_bash_edited"
			},
			{
				id: "format_shellharden"
				tool: "shell-validation"
				mode: "write"
				mutates_source: true
				after: "edit_source"
				blocks_on: "shellharden_failed"
			},
			{
				id: "format_shfmt"
				tool: "shell-validation"
				mode: "write"
				mutates_source: true
				after: "format_shellharden"
				blocks_on: "shfmt_failed"
			},
			{
				id: "lint_source_shellcheck"
				tool: "shell-validation"
				mode: "check"
				mutates_source: false
				after: "format_shfmt"
				blocks_on: "shellcheck_source_failed"
			},
			{
				id: "generate_bashly"
				tool: "bashly"
				mode: "generate"
				mutates_source: false
				after: "lint_source_shellcheck"
				blocks_on: "bashly_generate_failed"
			},
			{
				id: "report"
				tool: "report"
				mode: "check"
				mutates_source: false
				after: "generate_bashly"
				blocks_on: ""
			},
		]
		generate_bashly: {
			command: ["bashly", "generate"]
			env: {
				BASHLY_FORMATTER: "none"
			}
			source_mutation_guard: true
			blocks_on: "bashly_generate_failed"
		}
	}

	commandRules: [
		for r in repopkg.command_rules {
			{
				kind: r.kind
				pattern: r.pattern
				decision: r.decision
				justification: r.justification
			}
		},
	]
}
