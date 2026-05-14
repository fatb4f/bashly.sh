---
name: bashly-settings
description: Use when Bashly path/layout behavior depends on bashly-settings.yml, settings.yml, source_dir, config_path, target_dir, command directory, formatter, or environment settings.
---

# Bashly settings

Settings determine where Bashly reads source and writes generated artifacts.

Workflow:

1. Locate `bashly-settings.yml` or `settings.yml`.
2. Read effective path settings.
3. Resolve paths relative to project root.
4. Record the result in `.codex/frames/active-project.md` when useful.
5. Only then edit config or partials.
