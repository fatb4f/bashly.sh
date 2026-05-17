#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/agentgen-gomplate.sh [--project-root PATH] [--output-root PATH] [--templates-dir PATH] [--cue-package PKG]

Render repo-local Codex surfaces from CUE-exported JSON via gomplate.
USAGE
}

project_root="."
output_root=""
templates_dir="./agent-sdk/templates"
cue_package="./agent-sdk/codex"

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
    --templates-dir)
      templates_dir="${2:?agentgen-gomplate: missing value for --templates-dir}"
      shift 2
      ;;
    --templates-dir=*)
      templates_dir="${1#--templates-dir=}"
      shift
      ;;
    --cue-package)
      cue_package="${2:?agentgen-gomplate: missing value for --cue-package}"
      shift 2
      ;;
    --cue-package=*)
      cue_package="${1#--cue-package=}"
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

# Ensure templates_dir is absolute if it exists, otherwise leave it as is 
# (in case it relies on resolving from project_root down the line or is already absolute)
if [[ "$templates_dir" != /* ]]; then
  templates_dir="$project_root/$templates_dir"
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

cue export "$cue_package" -e generationData --out json >"$tmp/generationData.json"

mkdir -p \
  "$output_root/.codex/frames" \
  "$output_root/.codex/generated" \
  "$output_root/.codex/rules"

gomplate -c data="$tmp/generationData.json" \
  -f "$templates_dir/repo-frame.md.tmpl" \
  -o "$output_root/.codex/frames/repo-frame.md"

gomplate -c data="$tmp/generationData.json" \
  -f "$templates_dir/skills.md.tmpl" \
  -o "$output_root/.codex/frames/skills.md"

gomplate -c data="$tmp/generationData.json" \
  -f "$templates_dir/workflow.md.tmpl" \
  -o "$output_root/.codex/frames/workflow.md"

gomplate -c data="$tmp/generationData.json" \
  -f "$templates_dir/default.rules.tmpl" \
  -o "$output_root/.codex/rules/default.rules"

cue export "$cue_package" -e skillIndex --out json >"$output_root/.codex/generated/skill-index.json"
cue export "$cue_package" -e surfaceIndex --out json >"$output_root/.codex/generated/surface-index.json"
