package bashly_workflow

#SkillID: "bashly" | "shell-validation" | "bats-core" | "shellspec" | "argc" | "bash-ast" | "tree-sitter"

workflow: {
	name: "bashly-source-edit"

	skills: [...#SkillID] & [
		"bashly",
		"shell-validation",
		"argc",
		"bash-ast",
		"tree-sitter",
		"bats-core",
		"shellspec",
	]

	steps: {
		inspect: {
			skills: ["bashly", "argc", "bash-ast", "tree-sitter"]
			purpose: "inspect Bashly config, source scripts, argv context, and optional structural evidence"
		}

		edit_source: {
			skills: ["bashly", "argc", "bash-ast", "tree-sitter"]
			purpose: "edit Bashly config or source scripts only"
			allowed_writes: ["src/*.sh", "bashly.yml", "src/bashly.yml", "settings.yml", "bashly-settings.yml"]
			generated_bash_manual_edits: false
		}

		pre_commit_ci: {
			skills: ["shell-validation", "bashly", "bats-core", "shellspec"]
			format: {
				order: ["shellharden", "shfmt"]
				policy: "shellharden first, shfmt second"
			}
			lint_source: {
				tool: "shellcheck"
				after: "format"
			}
			generate: {
				tool: "bashly generate"
				must_not_format_source: true
				must_not_harden_source: true
				must_not_mutate_source: true
			}
			lint_generated: {
				required: false
				status: "deferred"
			}
			test_if_present: {
				required: false
				status: "deferred"
				tools: ["bats", "shellspec"]
			}
			report: {
				kind: "ci_report"
			}
		}
	}

	gate: {
		kind: "ci_job"
		blocks_on: [
			"unsafe_write_target",
			"generated_bash_edited",
			"shellharden_failed",
			"shfmt_failed",
			"shellcheck_source_failed",
			"bashly_generate_failed",
		]
		deferred: [
			"shellcheck_generated",
			"bats",
			"shellspec",
		]
	}
}
