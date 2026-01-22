#!/bin/bash
# Check for optional dependencies and inform user of available capabilities
set -uo pipefail

# Check GitHub CLI
gh_status="Not found"
if command -v gh &> /dev/null; then
  gh_status="Available"
fi

# Check Brainstorm Plugin (relative to plugin root or in project)
brainstorm_status="Not installed"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [[ -n "$PLUGIN_ROOT" && -f "${PLUGIN_ROOT}/../brainstorm.claude/.claude-plugin/plugin.json" ]]; then
  brainstorm_status="Available"
elif [[ -f "${PROJECT_DIR}/brainstorm.claude/.claude-plugin/plugin.json" ]]; then
  brainstorm_status="Available"
fi

# Check Output Directory
output_status="docs/planning/"
if [[ ! -d "${PROJECT_DIR}/docs/planning" ]]; then
  output_status="docs/planning/ (will be created)"
fi

# Output status
cat << EOF
Planner Plugin Ready
├── GitHub CLI: $gh_status
├── Brainstorm Plugin: $brainstorm_status
└── Output: $output_status
EOF

# Return JSON for hook system
echo '{"status": "ok"}'
exit 0
