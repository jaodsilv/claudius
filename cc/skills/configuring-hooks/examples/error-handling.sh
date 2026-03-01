#!/usr/bin/env bash
# Example: Error handling patterns for hooks
set -euo pipefail

# Trap unexpected errors - still output valid JSON
trap 'jq -n "{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"allow\"}, \"error\": \"Unexpected script failure\"}" && exit 0' ERR

# Safe environment variable access with defaults
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-{}}"

# Method 1: Conditional command execution
if output=$(validate_tool "$TOOL_NAME" 2>&1); then
    # Command succeeded
    jq -n --arg out "$output" '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}, "validation": $out}'
    exit 0
else
    # Command failed - handle gracefully
    jq -n --arg err "$output" '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}, "warning": $err}'
    exit 0
fi

# Method 2: Or-clause fallback (alternative pattern)
# result=$(risky_command 2>&1) || result="default_value"

# Method 3: Temporary disable strict mode (alternative pattern)
# set +e
# output=$(may_fail 2>&1)
# status=$?
# set -e
# if [[ $status -ne 0 ]]; then
#     # Handle error
# fi
