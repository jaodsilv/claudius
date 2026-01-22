#!/bin/bash
set -euo pipefail
# Check for planner plugin dependencies and provide template paths
# Returns JSON with systemMessage for warnings and additionalContext for templates

# Get plugin root (parent of hooks/scripts)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"

warnings=""
info_msgs=""

# Check gh CLI
if ! command -v gh &> /dev/null; then
    warnings="GitHub CLI (gh) not found - /planner:prioritize requires gh for issue fetching. Install from https://cli.github.com/"
fi

# Check gh authentication if gh exists
if command -v gh &> /dev/null; then
    if ! gh auth status &> /dev/null; then
        if [ -n "$warnings" ]; then
            warnings="$warnings | gh CLI not authenticated - run 'gh auth login' for GitHub features"
        else
            warnings="gh CLI not authenticated - run 'gh auth login' for GitHub features"
        fi
    fi
fi

# Check for brainstorm plugin (optional)
brainstorm_available="false"
if [ -f "${PLUGIN_ROOT}/../brainstorm.claude/.claude-plugin/plugin.json" ] || [ -f "../brainstorm.claude/.claude-plugin/plugin.json" ]; then
    brainstorm_available="true"
    info_msgs="Brainstorm Pro detected - /planner:gather-requirements can use enhanced brainstorming"
fi

# Build template paths context
# Use forward slashes for cross-platform compatibility
template_dir="${PLUGIN_ROOT}/templates"
template_context="Planner Plugin Template Paths (use these exact paths when loading templates):
- Review Report: ${template_dir}/review-report.md
- Roadmap: ${template_dir}/roadmap.md
- Prioritization Matrix: ${template_dir}/prioritization-matrix.md
- Requirements Summary: ${template_dir}/requirements-summary.md
- Ideas Synthesis: ${template_dir}/ideas-synthesis.md
- Base Sections: ${template_dir}/_base.md
- Orchestrating Reviews Report: ${PLUGIN_ROOT}/skills/orchestrating-reviews/report-template.md"

# Build JSON output
# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' '
}

template_context_escaped=$(escape_json "$template_context")

# Build the output JSON
if [ -n "$warnings" ]; then
    echo "{\"systemMessage\": \"[planner] Warning: $warnings\", \"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"$template_context_escaped\"}}"
elif [ -n "$info_msgs" ]; then
    echo "{\"systemMessage\": \"[planner] $info_msgs\", \"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"$template_context_escaped\"}}"
else
    echo "{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"$template_context_escaped\"}}"
fi

exit 0
