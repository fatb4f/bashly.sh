---
name: bashly
description: Use for Bashly CLI project work: inspecting settings, changing bashly.yml, editing Bash source partials, regenerating artifacts, and validating CLI behavior.
---

# Bashly skill

Use the local upstream Bashly skill when available under `refs/bashly-ai-kit/skills/bashly/SKILL.md`.

Repository-local contract:

1. Resolve the Bashly project root.
2. Inspect effective settings before assuming paths.
3. Treat Bashly YAML/settings as CLI authority.
4. Treat partials as implementation authority.
5. Regenerate generated scripts after source/config changes.
6. Do not manually patch generated output unless explicitly requested.
7. Validate help, success path, error path, and exit codes.
