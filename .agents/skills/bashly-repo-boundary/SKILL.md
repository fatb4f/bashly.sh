---
name: bashly-repo-boundary
description: Use before editing to resolve the active Bashly project root, settings file, source directory, config path, target directory, and generated artifact surface.
---

# Bashly repo boundary

Before editing, identify the active Bashly project.

A project root may contain:

- `bashly.yml`
- `src/bashly.yml`
- `bashly-settings.yml`
- `settings.yml`

Required output for task planning:

```txt
project_root:
settings_file:
source_dir:
config_path:
target_dir:
generated_outputs:
```

Do not assume default Bashly paths until settings have been inspected.
