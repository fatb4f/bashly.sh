package bashlybridge

#ApplyChunkRequest: {
	selector: string
	action: "replace_body" | "replace_node" | "insert_before" | "insert_after" | "append"
	guards?: {
		file_sha256?: string
		node_sha256?: string
		changedtick?: int
	}
	content: string
}

#ApplyChunkResult: {
	ok: bool
	selector: string
	action: string
	phases: [...string]
	updated_projection?: #ProjectProjection
	diagnostics?: [...#Diagnostic]
	gate?: {
		green: bool
		blocking_count: int
	}
}
