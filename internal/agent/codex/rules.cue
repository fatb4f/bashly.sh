package codex

import (
	"strings"

	"github.com/fatb4f/bashly.sh/internal/agent/repo"
)

commandRules: repo.command_rules

defaultRules: strings.Join([
	for r in commandRules {
		"""
		\(r.kind)_rule(
		    pattern = [\(strings.Join([for p in r.pattern { "\"\(p)\"" }], ", "))],
		    decision = "\(r.decision)",
		    justification = "\(r.justification)",
		)
		"""
	},
], "\n\n")
