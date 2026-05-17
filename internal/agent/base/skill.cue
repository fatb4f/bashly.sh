package base

#SkillID: string

#Skill: {
	id!: #SkillID
	path!: string
	entrypoint!: string
	purpose!: string

	required_tools?: [...string]
	optional_tools?: [...string]
	triggers?: [...string]
	delegates?: [...#SkillID]

	status: *"active" | "deferred" | "experimental" | "deprecated"
	load_policy: *"on_select" | "always" | "never"
}

#SkillIndexEntry: {
	id!: #SkillID
	path!: string
	entrypoint!: string
	purpose!: string
	status!: "active" | "deferred" | "experimental" | "deprecated"
	triggers?: [...string]
}
