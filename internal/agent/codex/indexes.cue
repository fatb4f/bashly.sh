package codex

import "github.com/fatb4f/bashly.sh/internal/agent/repo"

skillOrder: [
	"argc",
	"bash-ast",
	"bashly",
	"bats-core",
	"shell-validation",
	"shellspec",
	"tree-sitter",
]

skillIndex: [
	for id in skillOrder {
		let s = repo.skills[id]
		{
			id: s.id
			path: s.path
			entrypoint: s.entrypoint
			purpose: s.purpose
			status: s.status
			triggers: s.triggers
		}
	}
]

surfaceIndex: repo.generated_surfaces
