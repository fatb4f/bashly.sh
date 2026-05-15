package bashlybridge

#ApplyChunkRequest: {
	target: #ApplyTarget
	action: #ApplyAction
	guard?: #ApplyGuard
	selector?: string
	content?: string
	guards?: #ApplyGuard
	finalize?: bool
	pipeline?: #ApplyPipeline
}

#ApplyChunkResult: {
	applied: bool
	ok?: bool
	selector: string
	path?: string
	action?: string
	phases: #ApplyPhases
	projection?: #BashlyProjectProjection
	diagnostics: [...#Diagnostic]
	gate: #Gate
	error?: #ApplyError
}

#ApplyTarget: {
	selector: string
}

#ApplyAction: {
	kind: "replace_body" | "replace_node" | "insert_before" | "insert_after" | "append"
	content: string
}

#ApplyGuard: {
	file_sha256?: string
	node_sha256?: string
	changedtick?: int
}

#ApplyPhases: {
	projected: bool
	resolved: bool
	guarded: bool
	mutated: bool
	normalize: bool
	formatted: bool
	written: bool
	linted: bool
	diagnostics_settled: bool
	reprojected: bool
}

#ApplyPipeline: {
	finalize?: bool
	normalize?: bool
	format?: bool
	write?: bool
	lint?: bool
	diagnostics_wait?: bool
}

#ApplyError: {
	code: string
	message: string
	selector?: string
	path?: string
}
