package repo

import "github.com/fatb4f/bashly.sh/internal/agent/base"

#SkillID: base.#SkillID

skills: {
	bashly: base.#Skill & {
		id: "bashly"
		path: ".agents/skills/bashly"
		entrypoint: ".agents/skills/bashly/SKILL.md"
		purpose: "Bashly source/config workflow and generated artifact boundary."
		required_tools: ["bashly"]
		optional_tools: ["ruby", "argc", "bash-ast", "tree-sitter", "sem"]
		triggers: ["bashly", "generated cli", "source script", "bashly.yml"]
		delegates: ["shell-validation", "bats-core", "shellspec"]
	}

	"shell-validation": base.#Skill & {
		id: "shell-validation"
		path: ".agents/skills/shell-validation"
		entrypoint: ".agents/skills/shell-validation/SKILL.md"
		purpose: "Shell normalization, formatting, linting, and local CI gate interpretation."
		required_tools: ["shfmt", "shellcheck"]
		optional_tools: ["shellharden"]
		triggers: ["shellharden", "shfmt", "shellcheck", "format", "lint"]
	}

	"bats-core": base.#Skill & {
		id: "bats-core"
		path: ".agents/skills/bats-core"
		entrypoint: ".agents/skills/bats-core/SKILL.md"
		purpose: "Black-box Bash CLI behavior tests."
		optional_tools: ["bats"]
		status: "deferred"
		triggers: ["bats", "behavior tests"]
	}

	"tree-sitter": base.#Skill & {
		id: "tree-sitter"
		path: ".agents/skills/tree-sitter"
		entrypoint: ".agents/skills/tree-sitter/SKILL.md"
		purpose: "Structural parsing and grammar evidence for shell source."
		status: "experimental"
		triggers: ["tree-sitter", "parse tree", "structural evidence"]
	}
}

skillIndex: [...base.#SkillIndexEntry] & [
	{
		id: skills.bashly.id
		path: skills.bashly.path
		entrypoint: skills.bashly.entrypoint
		purpose: skills.bashly.purpose
		status: skills.bashly.status
		triggers: skills.bashly.triggers
	},
	{
		id: skills."shell-validation".id
		path: skills."shell-validation".path
		entrypoint: skills."shell-validation".entrypoint
		purpose: skills."shell-validation".purpose
		status: skills."shell-validation".status
		triggers: skills."shell-validation".triggers
	},
	{
		id: skills."bats-core".id
		path: skills."bats-core".path
		entrypoint: skills."bats-core".entrypoint
		purpose: skills."bats-core".purpose
		status: skills."bats-core".status
		triggers: skills."bats-core".triggers
	},
	{
		id: skills."tree-sitter".id
		path: skills."tree-sitter".path
		entrypoint: skills."tree-sitter".entrypoint
		purpose: skills."tree-sitter".purpose
		status: skills."tree-sitter".status
		triggers: skills."tree-sitter".triggers
	},
]
