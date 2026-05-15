package bashlybridge

#ProjectProjection: {
	workspace: string
	settings_file: string
	source_dir: string
	config_path: string
	target_dir: string
	generated_outputs: [...string]
	test_dirs: [...string]
	selectors?: [...#SelectorProjection]
	diagnostics?: [...#Diagnostic]
}

#SourceProjection: {
	schema_version: 1
	workspace: string
	source: {
		dir: string
		files: [string]: #SourceFileProjection
	}
	selectors: [string]: #SourceSelectorProjection
	diagnostics: [...#Diagnostic]
}

#Gate: {
	green: bool
	blocking_count: int
	warning_count: int
	info_count: int
	blocking_codes: [...string]
}

#RefProjection: {
	kind: string
	key: string
	source_selector: string
	target_selector?: string
	path: string
	range?: #Range
}

#ArgcProjection: {
	facts: [...#ArgcFactProjection]
	refs: [...#ArgcRefProjection]
}

#ArgcFactProjection: {
	kind: string
	name: string
	source_file: string
	range: #Range
	selector: string
}

#ArgcRefProjection: {
	name: string
	source_file: string
	range: #Range
	selector: string
	resolved: bool
	target_selector?: string
}

#SourceFileProjection: {
	path: string
	file_sha256: string
	nvim: #NvimState
	entities: [...#SourceEntityProjection]
}

#SourceEntityProjection: {
	id: string
	kind: string
	path: string
	range: #Range
	hashes?: {
		file_sha256?: string
		node_sha256?: string
	}
	nvim: #NvimState
}

#SourceSelectorProjection: {
	id: string
	kind: string
	path: string
	range?: #Range
	parent?: string
	children?: [...string]
	hashes?: {
		file_sha256?: string
		node_sha256?: string
	}
	nvim?: #NvimState
}

#BashlyGraphProjection: {
	schema_version: 1
	workspace: string
	bashly: {
		config_path: string
		model_hash: string
		commands: [...#BashlyCommandProjection]
	}
	selectors: [string]: #GraphSelector
	diagnostics: [...#Diagnostic]
}

#BashlyProjectProjection: {
	schema_version: 1
	workspace: string
	bashly: {
		config_path: string
		model_hash: string
		commands: [...#BashlyCommandProjection]
	}
	source: #SourceProjection.source
	selectors: [string]: #SourceSelectorProjection | #GraphSelector | #SelectorProjection | #ArgcSelectorProjection
	refs?: [...#RefProjection]
	argc?: #ArgcProjection
	diagnostics: [...#Diagnostic]
	gate: #Gate
}

#BashlyCommandProjection: {
	id: string
	name: string
	path: [...string]
	source_file: string
	handler_selector: string | null
	flags: [...string]
	args: [...string]
	env: [...string]
}

#GraphSelector: {
	id: string
	kind: string
	path: string
	parent?: string
	children: [...string]
	hashes?: {
		file_sha256: string
	}
}

#SelectorProjection: {
	selector: string
	kind: string
	path: string
	range?: #Range
	parent?: string
	children?: [...string]
	file_sha256?: string
	node_sha256?: string
	changedtick?: int
	bufnr?: int
}

#ArgcSelectorProjection: {
	id: string
	kind: string
	path: string
	range?: #Range
	parent?: string
	children?: [...string]
}

#Range: {
	start_line: int
	start_column: int
	end_line: int
	end_column: int
}

#NvimState: {
	bufnr: int
	changedtick: int
}
