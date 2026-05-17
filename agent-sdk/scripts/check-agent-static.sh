#!/usr/bin/env bash
set -euo pipefail

cue vet -c ./agent-sdk/codex/...

cue export ./agent-sdk/codex -e repoFrame --out text >/dev/null
cue export ./agent-sdk/codex -e skillFrame --out text >/dev/null
cue export ./agent-sdk/codex -e workflowFrame --out text >/dev/null
cue export ./agent-sdk/codex -e generationData --out json >/dev/null
cue export ./agent-sdk/codex -e skillIndex --out json >/dev/null
cue export ./agent-sdk/codex -e surfaceIndex --out json >/dev/null
cue export ./agent-sdk/codex -e defaultRules --out text >/dev/null
