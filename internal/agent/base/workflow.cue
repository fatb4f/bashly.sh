package base

#PhaseID: "inspect" | "edit_source" | "verify_source" | "format" | "lint_source" | "generate" | "format_shellharden" | "format_shfmt" | "lint_source_shellcheck" | "generate_bashly" | "report" | "lint_generated" | "test_if_present"
#PhaseMode: "write" | "check" | "generate"
#Blocker: "unsafe_write_target" | "generated_bash_edited" | "shellharden_failed" | "shfmt_failed" | "shellcheck_source_failed" | "bashly_generate_failed" | "shellcheck_generated_failed" | "bats_failed" | "shellspec_failed"
#DeferredID: "lint_generated" | "bats-core" | "shellspec"

#Workflow: {
	name!: string
	phases!: [...#Phase]
	deferred?: [...#DeferredID]
}

#Phase: {
	id!: #PhaseID
	tool!: string
	mode!: #PhaseMode
	command?: [...string]
	env?: [string]: string
	mutates_source: bool | *false
	after?: #PhaseID | ""
	blocks_on?: #Blocker | ""
	source_mutation_guard?: bool
}
