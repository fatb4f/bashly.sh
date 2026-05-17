package base

#Workflow: {
	name!: string
	phases!: [...#Phase]
}

#Phase: {
	id!: string
	tool!: string
	mode!: "write" | "check" | "generate"
	mutates_source: bool | *false
	after?: string
	blocks_on?: string
}
