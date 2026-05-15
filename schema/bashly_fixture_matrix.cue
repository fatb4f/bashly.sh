package bashlybridge

#FixtureMatrixResult: {
	ok: bool
	fixtures: [...#FixtureResult]
}

#FixtureResult: {
	name: string
	ok: bool
	skipped?: bool
	reason?: string
	phases: {
		project?: _
		apply?: _
		finalize?: _
		generate_verify?: _
		diagnostics?: _
	}
	expected: {
		diagnostics?: [...string]
		failures?: [...string]
		gate_blocking?: bool
	}
	observed: {
		diagnostics?: [...string]
		failures?: [...string]
		gate_blocking?: bool
	}
}
