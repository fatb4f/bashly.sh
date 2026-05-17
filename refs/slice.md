## Verdict

```txt
Use Hof as the pattern.
Use CUE as authority/projection engine.
Use gomplate as the materializer.
Do not import Hof as a runtime dependency.
Do not use gomplate to parse CUE directly.
Do not make Go adapter M4 unless gomplate check-mode becomes insufficient.
```

This mostly confirms the pasted gomplate assessment, but with one update: the uploaded `gomplate-main` repo is even more favorable than the earlier note, because the repo snapshot is on `github.com/hairyhenderson/gomplate/v5` and its `go.mod` already depends on `cuelang.org/go v0.16.1`. The earlier note framed gomplate as the materializer and Hof as pattern-only, with CUE exporting JSON into gomplate rather than gomplate reading CUE directly.  The CUE note also correctly identified the missing native piece: stable Hof-style `template + selected value + schema + output path` materialization. 

## Repo assessment

| Repo             | Use                                                                                                                            | Do not use                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| `hof-_next`      | Pattern source: `value @ schema -> template -> output`, enrichers, generator target schema, datafile/template distinction      | Full Hof dependency, flow runtime, diff3 machinery, module system      |
| `gomplate-main`  | Text/materialization adapter: templates, `context`, `datasources`, `inputFiles/outputFiles`, `inputDir/outputMap`, config file | Direct CUE parsing; `data.CUE` is still marked unreleased in docs      |
| `bashly.sh-main` | Target repo already has the right CUE authority graph                                                                          | Current M4 should be changed away from `go generate + cue exp writefs` |

## Key finding in `bashly.sh`

Current state:

```txt
internal/agent/base/
  schemas

internal/agent/repo/
  repo facts
  skills
  workflow
  command rules
  generated surfaces
  discovery policy

internal/agent/codex/
  frames
  indexes
  rules
```

That is the right spine.

But `internal/agent/codex/frames.cue` currently renders Markdown directly using `strings.Join`. That is acceptable for M3 proof-of-projection, but it is the wrong long-term split if copying the Hof pattern.

Target split:

```txt
CUE:
  typed authority
  normalized/enriched projection values
  generation target map

gomplate:
  markdown/rules rendering
  filesystem materialization

shell/just:
  orchestration
  drift check
```

## M4 correction

Replace the existing M4 plan:

```txt
go generate ./internal/agent
cue exp writefs
```

with:

```txt
cue export generationData
gomplate render templates
cue export JSON indexes directly
git diff generated surfaces
```

Recommended generated surface plan:

```txt
internal/agent/templates/
  repo-frame.md.tmpl
  skills.md.tmpl
  workflow.md.tmpl
  default.rules.tmpl

.codex/
  frames/
    repo-frame.md
    skills.md
    workflow.md
  generated/
    skill-index.json
    surface-index.json
    route-index.json
  rules/
    default.rules
```

## CUE schema shape

Add a Hof-like generation target schema:

```cue
package base

#GenerationTarget: {
	name!: string
	kind!: "frame" | "index" | "rule"
	input!: string          // CUE expression exported for this target
	schema?: string         // optional schema expression
	template?: string       // absent for direct JSON export
	output!: string
	format!: "markdown" | "json" | "text"
	materializer!: "gomplate" | "cue-export"
	edit_policy!: "never-hand-edit"
}
```

Then define repo-local targets:

```cue
package repo

generation_targets: [...base.#GenerationTarget] & [
	{
		name: "repo-frame"
		kind: "frame"
		input: "generationData.repoFrame"
		schema: "#RepoFrame"
		template: "internal/agent/templates/repo-frame.md.tmpl"
		output: ".codex/frames/repo-frame.md"
		format: "markdown"
		materializer: "gomplate"
		edit_policy: "never-hand-edit"
	},
	{
		name: "skill-index"
		kind: "index"
		input: "skillIndex"
		output: ".codex/generated/skill-index.json"
		format: "json"
		materializer: "cue-export"
		edit_policy: "never-hand-edit"
	},
]
```

## Enrich-before-render target

Right now `repo.skills` is mostly curated. Keep that as authority, but enrich it before rendering:

```txt
raw:
  id
  purpose
  required_tools
  optional_tools
  triggers
  status

enriched:
  path
  entrypoint
  has_local_skill
  external_skill
  load_policy
  reference_policy
  codex_hint
  delegates
  gate_contribution
```

For this repo, that matters because `.agents/skills/*/references` contains large cold corpora. The generated index should tell Codex:

```txt
load SKILL.md only after selection
do not crawl references unless selected by the skill
treat bashly-docs/tree-sitter/shellspec references as cold evidence
```

## Issues to fix before materialization

### 1. Skill authority duplication

There are two skill declarations:

```txt
internal/agent/repo/skills.cue
.agents/skills/*/skill.cue
```

They disagree in several places. Examples:

```txt
argc:
  local skill.cue says argc is optional
  repo/skills.cue says argc is required

shell-validation:
  local skill.cue says shellharden is optional
  repo/skills.cue says shellharden is required

repo/skills.cue adds:
  triggers
  delegates
  status

local skill.cue mostly omits them
```

Make one side authoritative.

Best choice:

```txt
internal/agent/repo/skills.cue = authority
.agents/skills/*/skill.cue = generated compatibility stubs or removed
```

### 2. External skill placeholders are not modeled

These exist as plain files:

```txt
.agents/skills/cue
.agents/skills/repo-search
.agents/skills/sem
```

But `.codex/AGENTS.md` says every skill under `.agents/skills/` is a directory with `SKILL.md`, `AGENTS.md`, and `skill.cue`.

Fix by modeling them explicitly:

```cue
externalSkills: {
	cue: {
		id: "cue"
		path: "/home/_404/.local/share/codex/skills/cue"
		load_policy: "on_select"
		status: "external"
	}
	sem: {
		id: "sem"
		path: "/home/_404/.local/share/codex/skills/sem"
		load_policy: "on_select"
		status: "external"
	}
}
```

Or move those pointer files out of `.agents/skills`.

### 3. `schema/bashly_workflow.cue` is still duplicate authority

It is marked transitional, but it still duplicates workflow/gate policy.

Target:

```txt
schema/bashly_workflow.cue
  imports internal/agent/repo
  projects compatibility shape
```

Not:

```txt
schema/bashly_workflow.cue
  redefines the workflow independently
```

## Recommended next slice

```txt
Current state:
  CUE authority graph exists.
  Codex projections exist as CUE-rendered strings.
  Generated surface list exists.
  M4 still points at go generate + cue exp writefs.

Target state:
  CUE exports one generationData object plus direct JSON indexes.
  gomplate renders markdown/rule text from exported JSON.
  generated surfaces are committed and drift-checked.
  skill-local duplication is either generated or deprecated.

Path:
  1. Add generationData in internal/agent/codex.
  2. Add internal/agent/templates/*.tmpl.
  3. Replace M4 plan with scripts/agentgen-gomplate.sh.
  4. Add scripts/check-agent-generated.sh.
  5. Add generated-surface drift check to CI.
  6. Move skill.cue duplication behind one authority decision.

Heads-up:
  Do not solve MCP yet.
  Do not introduce Hof.
  Do not use gomplate CUE functions.
  Do not let generated Markdown become authority.
```

## Minimal adapter contract

```sh
#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cue export ./internal/agent/codex -e generationData --out json > "$tmp/generationData.json"

mkdir -p .codex/frames .codex/generated .codex/rules

gomplate -c data="$tmp/generationData.json" \
  -f internal/agent/templates/repo-frame.md.tmpl \
  -o .codex/frames/repo-frame.md

gomplate -c data="$tmp/generationData.json" \
  -f internal/agent/templates/skills.md.tmpl \
  -o .codex/frames/skills.md

gomplate -c data="$tmp/generationData.json" \
  -f internal/agent/templates/workflow.md.tmpl \
  -o .codex/frames/workflow.md

gomplate -c data="$tmp/generationData.json" \
  -f internal/agent/templates/default.rules.tmpl \
  -o .codex/rules/default.rules

cue export ./internal/agent/codex -e skillIndex --out json > .codex/generated/skill-index.json
cue export ./internal/agent/codex -e surfaceIndex --out json > .codex/generated/surface-index.json
```

Check mode:

```sh
scripts/agentgen-gomplate.sh
git diff --exit-code -- .codex/frames .codex/generated .codex/rules
```

## Final architecture

```txt
CUE:
  source of truth
  schema validation
  graph normalization
  enriched projections
  generation target map

gomplate:
  deterministic rendering
  file materialization
  committed config/template surface

shell/just:
  command adapter
  drift check
  CI integration

Go adapter:
  later only if generation policy becomes too complex for shell + gomplate
```

Best immediate move: **rewrite M4/M5 around gomplate, then tighten skill authority duplication before generating committed Codex surfaces.**

