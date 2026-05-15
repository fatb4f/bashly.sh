package bashlybridge

#BashlyGenerateVerifyRequest: {
	project?: string
	cwd?: string
	include_tests?: bool | *true
	include_sem?: bool | *false
	timeout_ms?: int | *30000
}

#BashlyGenerateVerifyResult: {
	ok: bool
	project: {
		root: string
		config?: string
		generated_executable?: string
	}
	phases: {
		discover: #PhaseResult
		generate: #PhaseResult
		derive_executable: #PhaseResult
		shellcheck_generated: #PhaseResult
		tests?: #PhaseResult
		sem?: #PhaseResult
	}
	evidence: [...#Evidence]
	errors?: [...#GenerateVerifyError]
}

#PhaseResult: {
	ok: bool
	skipped?: bool
	command?: [...string]
	exit_code?: int
	stdout?: string
	stderr?: string
	duration_ms?: int
}

#Evidence: {
	kind: string
	path?: string
	command?: [...string]
	summary?: string
}

#GenerateVerifyError: {
	code: string
	message: string
	phase?: string
	path?: string
}
