#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check-agent-generated.sh [--project-root PATH]

Check that generated Codex surfaces match the CUE/gomplate sources.
USAGE
}

project_root="."

while (($# > 0)); do
  case "$1" in
    --project-root)
      project_root="${2:?check-agent-generated: missing value for --project-root}"
      shift 2
      ;;
    --project-root=*)
      project_root="${1#--project-root=}"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'check-agent-generated: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

project_root="$(cd "$project_root" && pwd -P)"
tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

if [[ ! -f "$project_root/.codex/frames/repo-frame.md" || ! -f "$project_root/.codex/generated/skill-index.json" || ! -f "$project_root/.codex/rules/default.rules" ]]; then
  printf 'check-agent-generated: committed .codex surface files are missing; run scripts/agentgen-gomplate.sh and commit the rendered outputs before using this check\n' >&2
  exit 1
fi

"$project_root/scripts/agentgen-gomplate.sh" \
  --project-root "$project_root" \
  --output-root "$tmp/out"

for path in \
  ".codex/frames" \
  ".codex/generated" \
  ".codex/rules"
do
  if ! diff -ruN "$project_root/$path" "$tmp/out/$path"; then
    printf 'check-agent-generated: drift detected in %s\n' "$path" >&2
    exit 1
  fi
done
