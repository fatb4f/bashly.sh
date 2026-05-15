package workflow

workflow: {
	name: "bashly-source-edit"
	model: "skill-guided-source-edit-with-ci-gate"

	purpose: "semantic edits to Bashly source scripts validated by local CI"

	skills: {
		inspect: ["bashly", "argc", "bash-ast", "tree-sitter"]
		edit_source: ["bashly", "argc", "bash-ast", "tree-sitter"]
		report: ["bashly", "shell-validation"]
	}

	pre_commit_ci: {
		format: {
			skill: "shell-validation"
			tools: ["shellharden", "shfmt"]
			order: ["shellharden", "shfmt"]
			auto_stage_allowed: true
			auto_stage_globs: ["src/*.sh"]
		}

		lint_source: {
			skill: "shell-validation"
			tool: "shellcheck"
			runs_after: "format"
			required: true
		}

		generate: {
			skill: "bashly"
			tool: "bashly"
			runs_after: "lint_source"
			required: true
			config_rule: "bashly generation must not format, harden, or mutate source scripts"
		}

		lint_generated: {
			skill: "shell-validation"
			tool: "shellcheck"
			required: false
			note: "deferred by root contract; projects may opt in"
		}

		test_if_present: {
			skills: ["bats-core", "shellspec"]
			required: false
			note: "deferred by root contract; projects may opt in"
		}

		report: {
			skills: ["bashly", "shell-validation"]
			kind: "ci_report"
			required: true
		}
	}

	gate: {
		kind: "ci_job"
		required: true
		commit_on_green: true
		block_on: [
			"unsafe_write_target",
			"generated_bash_edited",
			"format_failed",
			"source_shellcheck_failed",
			"bashly_generate_failed",
			"unexpected_file_change",
		]
		deferred_by_default: [
			"generated_shellcheck",
			"bats",
			"shellspec",
		]
	}
}
