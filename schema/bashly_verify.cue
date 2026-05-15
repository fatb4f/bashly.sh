package bashlybridge

#VerifyResult: {
	workspace: string
	green: bool
	blocking_count: int
	phases: [...string]
	diagnostics?: [...#Diagnostic]
}
