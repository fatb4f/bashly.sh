# Implementation Milestones

## Goal

Turn `bashly.sh` into a repo-local CUE-authored workflow surface where:

- CUE is the authority for repo semantics.
- Generated artifacts are the primary Codex-facing interface.
- Skills remain the human-readable operating protocol.
- MCP remains optional and only comes after the generated surfaces prove useful.

## Scope

This plan stays repo-local.

It does not introduce a global control plane or a cross-repo registry.
It focuses on the `bashly.sh` repository and the artifacts it already owns.

## Milestone 0: Stabilize the current contract

Deliverables:

- Keep `AGENTS.md` as the tiny boot contract.
- Keep `schema/bashly_workflow.cue` as the source workflow authority.
- Confirm the existing skill layout remains the local operating surface.

Exit criteria:

- The repository still follows the current source-edit / validate / report model.
- No generated artifact depends on manual editing.

## Milestone 1: Add minimal CUE module support

Deliverables:

- Add `cue.mod/module.cue` with only module identity and language version.
- Keep repo intelligence out of `module.cue`.

Exit criteria:

- `cue` recognizes the repo as a module root.
- The module file remains minimal and stable.

## Milestone 2: Define the internal authority graph

Deliverables:

- Add `internal/agent/base/` for reusable schema and rendering helpers.
- Add `internal/agent/repo/` for repo-specific facts, skills, workflow, and surfaces.
- Add `internal/agent/codex/` for Codex-facing projections.
- During migration, `schema/bashly_workflow.cue` remains the compatibility surface.
- After `internal/agent` is stable, `schema/bashly_workflow.cue` either imports or projects from `internal/agent`, or becomes deprecated.

Exit criteria:

- Repo semantics are expressed in CUE under `internal/*`.
- Workflow, skills, and command rules are no longer only embedded in prose.

## Milestone 3: Define Codex-facing projections

Deliverables:

- Add CUE values for:
  - `repoFrame`
  - `skillFrame`
  - `workflowFrame`
  - `skillIndex`
  - `defaultRules`
- Keep these as CUE-rendered values first, not files.
- Ensure `cue export` can inspect each projection independently.

Exit criteria:

```sh
cue export ./internal/agent/codex -e repoFrame --out text
cue export ./internal/agent/codex -e skillFrame --out text
cue export ./internal/agent/codex -e workflowFrame --out text
cue export ./internal/agent/codex -e skillIndex --out json
cue export ./internal/agent/codex -e defaultRules --out text
```

## Milestone 4: Add regeneration entrypoints

Deliverables:

- Add `internal/agent/gen.go`.
- Add `internal/agent/gen.cue`.
- Wire generation through `go generate`.
- Use `cue exp writefs` as the bulk file materialization mechanism.
- Generate:
  - `.codex/frames/repo-frame.md`
  - `.codex/frames/skills.md`
  - `.codex/frames/workflow.md`
  - `.codex/generated/skill-index.json`
  - `.codex/rules/default.rules`

Exit criteria:

```sh
go generate ./internal/agent
git diff -- .codex/frames .codex/generated .codex/rules
```

## Milestone 5: Add freshness and validation checks

Deliverables:

- Add a check that generated outputs match the CUE source.
- Extend the repo validation path so generated surfaces are verified in CI.
- Keep existing shell validation order intact.

Exit criteria:

- CI fails if generated artifacts drift from CUE.
- The repo has a clear source-of-truth to output pipeline.

## Milestone 6: Tighten discovery behavior

Deliverables:

- Encode the repo-local discovery order in generated frames.
- Make inventory questions resolve from `skill-index.json` before filesystem search.
- Keep skill docs as the fallback for procedural detail.

Exit criteria:

- Codex reads the generated index first for inventory questions.
- Repo search becomes a fallback rather than the default discovery path.

## Milestone 7: Evaluate MCP promotion

Deliverables:

- Identify repeated query patterns that are expensive through shell/export/parse.
- Decide whether a repo-local MCP adapter is justified.
- If needed, expose only the high-value query paths.

Candidate MCP targets:

- `repo_skill_index()`
- `repo_context_frame(task)`
- `repo_validation_plan()`
- `repo_prompt_route(prompt)`
- `repo_status()`

Exit criteria:

- MCP is added only if it materially reduces interface cost.
- CUE remains the authority even if MCP is introduced.

## Recommended Order

1. Minimal `cue.mod/module.cue`
2. Internal CUE authority graph
3. Codex-facing projection values
4. Materialized generated artifacts
5. Freshness checks in CI
6. Discovery tightening
7. Optional MCP promotion

## Not Yet

Do not start with:

- A global cross-repo registry
- A full control plane outside the repo
- MCP as the primary source of truth
- Generated `AGENTS.md` fragments as a first-class dependency

## Success Shape

When this is complete, the repo behaves like a GitOps-style app:

- CUE declares intent.
- Projection values render the concrete surfaces.
- Generation materializes the concrete surfaces.
- Validation checks drift.
- Codex consumes the compact outputs instead of crawling first.
