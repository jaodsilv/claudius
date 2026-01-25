#!/usr/bin/env bash
# Example: Capturing output and logging without corrupting JSON
set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-{}}"
LOG_FILE="/tmp/claude_hook.log"

# Debug output goes to stderr (not stdout)
echo "DEBUG: Processing tool $TOOL_NAME" >&2

# Log to file (not stdout)
{
    echo "----------------------------------------"
    echo "Timestamp: $(date -Iseconds)"
    echo "Tool: $TOOL_NAME"
    echo "Input: $TOOL_INPUT"
} >> "$LOG_FILE"

# Capture command output for processing
if output=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>&1); then
    echo "Extracted command: $output" >> "$LOG_FILE"
else
    echo "Failed to extract command: $output" >> "$LOG_FILE"
fi

# Background logging (doesn't block the hook)
(
    sleep 1
    echo "Async log at $(date)" >> "$LOG_FILE"
) &

# Only JSON goes to stdout
jq -n --arg tool "$TOOL_NAME" '{
    decision: "allow",
    logged: true,
    tool: $tool
}'

# CRITICAL: Explicit exit
exit 0
