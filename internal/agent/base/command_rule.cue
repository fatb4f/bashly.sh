package base

#CommandRuleKind: "prefix" | "exact"
#CommandDecision: "allow" | "prompt" | "forbidden"

#CommandRule: {
	kind!: #CommandRuleKind
	pattern!: [...string]
	decision!: #CommandDecision
	justification!: string
}
