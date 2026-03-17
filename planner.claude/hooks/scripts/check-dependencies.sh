#!/bin/bash
set -euo pipefail
# Check for planner plugin dependencies and provide template paths
# Returns JSON with systemMessage for warnings and additionalContext for templates

# Get plugin root from Claude Code environment
if [[ -f "${CLAUDE_PLUGIN_ROOT}/../brainstorm.claude/.claude-plugin/plugin.json" ]]; then
  brainstorm_status="Available"
fi

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
if [ -f "${CLAUDE_PLUGIN_ROOT}/../brainstorm.claude/.claude-plugin/plugin.json" ]; then
    brainstorm_available="true"
    info_msgs="Brainstorm plugin detected - /planner:gather-requirements can use enhanced brainstorming"
fi

$system_message=""
if [ -n "$warnings" ]; then
    $system_message="[planner] Warning: $warnings"
    if [ -n "$info_msgs" ]; then
        $system_message="$system_message\n[planner] $info_msgs"
    fi
elif [ -n "$info_msgs" ]; then
    $system_message="[planner] $info_msgs"
fi

# Build JSON output
# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' '
}

system_message_json=$(escape_json "$system_message")

# Build the output JSON
if [ -n "$system_message" ]; then
    echo "{\"systemMessage\": \"$system_message_json\"}"
fi

exit 0
