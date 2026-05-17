package agent

import "github.com/fatb4f/bashly.sh/agent-sdk/profiles/bash-cli:bashcli"

// For now, we simply re-export the pre-configured bash-cli profile from the SDK.
// Once bash-cli is fully refactored into a generic #BashCLI schema, this file 
// will be updated to instantiate it with bashly.sh-specific values.

surfaces: bashcli.surfaces
repo: bashcli.repo
skills: bashcli.skills
workflow: bashcli.workflow
discovery: bashcli.discovery
commandRules: bashcli.commandRules