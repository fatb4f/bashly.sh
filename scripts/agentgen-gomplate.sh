#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/agentgen-gomplate.sh [--project-root PATH] [--output-root PATH]

Render repo-local Codex surfaces from CUE-exported JSON via gomplate.
USAGE
}

project_root="."
output_root=""

while (($# > 0)); do
  case "$1" in
    --project-root)
      project_root="${2:?agentgen-gomplate: missing value for --project-root}"
      shift 2
      ;;
    --project-root=*)
      project_root="${1#--project-root=}"
      shift
      ;;
    --output-root)
      output_root="${2:?agentgen-gomplate: missing value for --output-root}"
      shift 2
      ;;
    --output-root=*)
      output_root="${1#--output-root=}"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'agentgen-gomplate: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$project_root"
project_root="$(pwd -P)"

if [[ -z "$output_root" ]]; then
  output_root="$project_root"
else
  mkdir -p "$output_root"
  output_root="$(cd "$output_root" && pwd -P)"
fi

need() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'agentgen-gomplate: missing required command: %s\n' "$cmd" >&2
    exit 127
  fi
}

need cue
need gomplate

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

cue export ./internal/agent/codex -e generationData --out json >"$tmp/generationData.json"

mkdir -p \
  "$output_root/.codex/frames" \
  "$output_root/.codex/generated" \
  "$output_root/.codex/rules"

gomplate -c data="$tmp/generationData.json" \
  -f "$project_root/internal/agent/templates/repo-frame.md.tmpl" \
  -o "$output_root/.codex/frames/repo-frame.md"

gomplate -c data="$tmp/generationData.json" \
  -f "$project_root/internal/agent/templates/skills.md.tmpl" \
  -o "$output_root/.codex/frames/skills.md"

gomplate -c data="$tmp/generationData.json" \
  -f "$project_root/internal/agent/templates/workflow.md.tmpl" \
  -o "$output_root/.codex/frames/workflow.md"

gomplate -c data="$tmp/generationData.json" \
  -f "$project_root/internal/agent/templates/default.rules.tmpl" \
  -o "$output_root/.codex/rules/default.rules"

cue export ./internal/agent/codex -e skillIndex --out json >"$output_root/.codex/generated/skill-index.json"
cue export ./internal/agent/codex -e surfaceIndex --out json >"$output_root/.codex/generated/surface-index.json"
