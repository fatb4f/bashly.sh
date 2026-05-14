---
name: yaml-contract
description: Use when editing or validating bashly.yml or YAML settings files that define the Bashly CLI contract.
---

# YAML contract

Treat `bashly.yml` as the CLI contract authority.

Preserve:

- command names
- aliases
- help text
- examples
- required args
- flags and environment variables
- exit behavior documented by examples/tests

Prefer schema/CUE/yq validation when available.
