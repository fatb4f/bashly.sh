package repo

import "github.com/fatb4f/bashly.sh/internal/agent/base"

workflow: base.#Workflow & {
	name: "bashly-source-edit"
	phases: [...base.#Phase] & [
		{
			id: "inspect"
			tool: "bashly"
			mode: "check"
			after: ""
			mutates_source: false
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
			id: "verify_source"
			tool: "shell-validation"
			mode: "check"
			after: "edit_source"
			mutates_source: false
			blocks_on: "shellcheck_source_failed"
		},
	]
}
