package bashlybridge

#DiagnosticSeverity: "error" | "warning" | "info" | "hint"

#Diagnostic: {
	source: string
	code: string
	severity: #DiagnosticSeverity
	message: string
	path?: string
	range?: #Range
	selector?: string
	node_id?: string
	blocking?: bool
}
