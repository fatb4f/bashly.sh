#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/pre-commit-ci.sh [--mode=check|write] [--project-root PATH]

Runs the Bashly source validation graph:
  format      shellharden, then shfmt
  lint_source shellcheck after formatting
  generate    bashly generate with Bashly formatting disabled

Modes:
  --mode=write  allow source formatting rewrites; intended for local pre-commit
  --mode=check  fail when formatting or generation would change files; intended for CI
USAGE
}

mode="check"
project_root="."

for arg in "$@"; do
  case "$arg" in
    --mode=check) mode="check" ;;
    --mode=write) mode="write" ;;
    --mode=*)
      mode="${arg#--mode=}"
      ;;
    --project-root=*)
      project_root="${arg#--project-root=}"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'pre-commit-ci: unknown argument: %s\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$mode" in
  check|write) ;;
  *)
    printf 'pre-commit-ci: invalid --mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac

cd "$project_root"
project_root="$(pwd -P)"

log() {
  printf '==> %s\n' "$*" >&2
}

need() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'pre-commit-ci: missing required command: %s\n' "$cmd" >&2
    exit 127
  fi
}

readarray_nul() {
  local -n _out="$1"
  _out=()
  while IFS= read -r -d '' item; do
    _out+=("$item")
  done
}

source_files=()
if [[ -d src ]]; then
  readarray_nul source_files < <(find src -type f -name '*.sh' -print0 | sort -z)
fi

bashly_config=""
if [[ -n "${BASHLY_CONFIG_PATH:-}" && -f "${BASHLY_CONFIG_PATH}" ]]; then
  bashly_config="${BASHLY_CONFIG_PATH}"
elif [[ -f src/bashly.yml ]]; then
  bashly_config="src/bashly.yml"
elif [[ -f bashly.yml ]]; then
  bashly_config="bashly.yml"
fi

snapshot_source_surface() {
  {
    for path in bashly.yml src/bashly.yml bashly-settings.yml settings.yml; do
      [[ -f "$path" ]] && printf '%s\0' "$path"
    done

    if [[ -d src ]]; then
      find src -type f -print0
    fi
  } | sort -z | while IFS= read -r -d '' path; do
    sha256sum -- "$path"
  done
}

format_sources() {
  if ((${#source_files[@]} == 0)); then
    log 'format: no src/*.sh files found; skipping shellharden and shfmt'
    return 0
  fi

  need shellharden
  need shfmt

  log 'format: shellharden'
  if [[ "$mode" == "write" ]]; then
    shellharden --replace -- "${source_files[@]}"
  else
    shellharden --check -- "${source_files[@]}"
  fi

  log 'format: shfmt'
  if [[ "$mode" == "write" ]]; then
    shfmt -w -i 2 -ci -sr -- "${source_files[@]}"
  else
    local diff_output
    if ! diff_output="$(shfmt -d -i 2 -ci -sr -- "${source_files[@]}")"; then
      printf '%s\n' "$diff_output"
      return 1
    fi
    if [[ -n "$diff_output" ]]; then
      printf '%s\n' "$diff_output"
      printf 'pre-commit-ci: shfmt reported formatting drift\n' >&2
      return 1
    fi
  fi
}

lint_source() {
  if ((${#source_files[@]} == 0)); then
    log 'lint_source: no src/*.sh files found; skipping shellcheck'
    return 0
  fi

  need shellcheck

  log 'lint_source: shellcheck'
  shellcheck --external-sources --shell=bash -- "${source_files[@]}"
}

generate_bashly() {
  if [[ -z "$bashly_config" ]]; then
    log 'generate: no bashly.yml or src/bashly.yml found; skipping bashly generate'
    return 0
  fi

  need bashly

  local before after
  before="$(mktemp)"
  after="$(mktemp)"
  trap 'rm -f "$before" "$after"' RETURN

  snapshot_source_surface >"$before"

  log 'generate: bashly generate with BASHLY_FORMATTER=none'

  if [[ "$bashly_config" != "src/bashly.yml" && -z "${BASHLY_CONFIG_PATH:-}" ]]; then
    BASHLY_CONFIG_PATH="$bashly_config" BASHLY_FORMATTER=none bashly generate
  else
    BASHLY_FORMATTER=none bashly generate
  fi

  snapshot_source_surface >"$after"

  if ! diff -u "$before" "$after" >/dev/null; then
    printf 'pre-commit-ci: bashly generate mutated source/config files; refusing generated-state drift\n' >&2
    diff -u "$before" "$after" || true
    return 1
  fi

  if [[ "$mode" == "check" ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git diff --quiet -- .; then
      printf 'pre-commit-ci: bashly generate left worktree changes; generated outputs may be stale\n' >&2
      git diff --stat -- . >&2
      return 1
    fi
  fi
}

format_sources
lint_source
generate_bashly

log 'pre-commit-ci: ok'
