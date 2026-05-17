#!/usr/bin/env bash
set -euo pipefail

cue vet -c ./internal/agent/...

cue export ./internal/agent/codex -e repoFrame --out text >/dev/null
cue export ./internal/agent/codex -e skillFrame --out text >/dev/null
cue export ./internal/agent/codex -e workflowFrame --out text >/dev/null
cue export ./internal/agent/codex -e skillIndex --out json >/dev/null
cue export ./internal/agent/codex -e surfaceIndex --out json >/dev/null
cue export ./internal/agent/codex -e defaultRules --out text >/dev/null
