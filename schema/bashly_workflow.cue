// Transitional compatibility schema.
// Canonical workflow authority lives in internal/agent/repo/workflow.cue.
// Keep this file aligned with the repo graph until Dynamic/Regen lands.
package bashly_workflow

#SkillID: "bashly" | "shell-validation" | "bats-core" | "shellspec" | "argc" | "bash-ast" | "tree-sitter"
#AdapterID: "pre_commit" | "ci"
#AdapterKind: "local_hook" | "ci_job"
#Authority: "advisory" | "blocking"
#MutationMode: "write" | "check"
#Blocker: "unsafe_write_target" | "generated_bash_edited" | "shellharden_failed" | "shfmt_failed" | "shellcheck_source_failed" | "bashly_generate_failed"
#Deferred: "lint_generated" | "bats-core" | "shellspec"

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

		verify_source: {
			skills: ["shell-validation", "bashly", "bats-core", "shellspec"]
			phases: ["format", "lint_source", "generate"]

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
				after: "lint_source"
				env: {
					BASHLY_FORMATTER: "none"
				}
				settings: {
					formatter: "none"
					purpose: "disable Bashly generated-output formatting during validation"
				}
				must_not_format_source: true
				must_not_harden_source: true
				must_not_mutate_source: true
				source_mutation_guard: true
			}

			lint_generated: {
				required: false
				status: "deferred"
			}

			test_if_present: {
				required: false
				status: "deferred"
				tools: ["bats-core", "shellspec"]
			}

			report: {
				kind: "validation_report"
			}
		}
	}

	adapters: {
		pre_commit: {
			kind: #AdapterKind & "local_hook"
			uses: "verify_source"
			authority: #Authority & "advisory"
			mode: #MutationMode & "write"
			format_source: true
			generate_mutates_source: false
			report: {
				kind: "local_report"
			}
		}

		ci: {
			kind: #AdapterKind & "ci_job"
			uses: "verify_source"
			authority: #Authority & "blocking"
			mode: #MutationMode & "check"
			format_source: false
			generate_mutates_source: false
			report: {
				kind: "ci_report"
			}
		}
	}

	gate: {
		kind: "ci_job"
		adapter: #AdapterID & "ci"
		blocks_on: [...#Blocker] & [
			"unsafe_write_target",
			"generated_bash_edited",
			"shellharden_failed",
			"shfmt_failed",
			"shellcheck_source_failed",
			"bashly_generate_failed",
		]
		deferred: [...#Deferred] & [
			"lint_generated",
			"bats-core",
			"shellspec",
		]
	}
}
