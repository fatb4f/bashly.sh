package base

#CommandRule: {
	kind!: "prefix" | "exact"
	pattern!: [...string]
	decision!: "allow" | "prompt" | "forbidden"
	justification!: string
}
