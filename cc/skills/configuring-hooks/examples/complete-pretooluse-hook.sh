#!/usr/bin/env bash
# Complete PreToolUse hook example with all best practices
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

BLOCKED_TOOLS=("rm" "sudo" "chmod")
LOG_FILE="${HOOK_LOG_FILE:-/tmp/pretooluse.log}"
DEBUG="${HOOK_DEBUG:-false}"

# ============================================================================
# Error Handling
# ============================================================================

# Trap for unexpected failures - still return valid JSON
trap 'jq -n "{\"decision\": \"allow\", \"error\": \"Hook failed unexpectedly\"}" && exit 0' ERR

# ============================================================================
# Helper Functions
# ============================================================================

log() {
    local level="$1"
    local message="$2"
    echo "[$(date -Iseconds)] [$level] $message" >> "$LOG_FILE"
    if [[ "$DEBUG" == "true" ]]; then
        echo "[$level] $message" >&2
    fi
}

is_blocked_tool() {
    local tool="$1"
    for blocked in "${BLOCKED_TOOLS[@]}"; do
        if [[ "$tool" == "$blocked" ]]; then
            return 0
        fi
    done
    return 1
}

# ============================================================================
# Main Logic
# ============================================================================

# Safe environment variable access
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-{}}"

log "INFO" "Processing tool: $TOOL_NAME"

# Check for empty tool name
if [[ -z "$TOOL_NAME" ]]; then
    log "WARN" "Empty tool name received"
    jq -n '{"decision": "allow", "warning": "Empty tool name"}'
    exit 0
fi

# Check blocked tools list
if is_blocked_tool "$TOOL_NAME"; then
    log "BLOCK" "Tool $TOOL_NAME is in blocked list"
    jq -n --arg tool "$TOOL_NAME" \
        '{"decision": "block", "reason": ("Tool " + $tool + " is not permitted")}'
    exit 0
fi

# For Bash tool, check the command
if [[ "$TOOL_NAME" == "Bash" ]]; then
    # Extract command from input
    command=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null) || command=""

    if [[ -n "$command" ]]; then
        log "INFO" "Bash command: $command"

        # Check for dangerous patterns
        if echo "$command" | grep -qE 'rm\s+-rf\s+/|sudo\s+rm|chmod\s+777'; then
            log "BLOCK" "Dangerous command pattern detected"
            jq -n --arg cmd "$command" \
                '{"decision": "block", "reason": "Command contains dangerous patterns"}'
            exit 0
        fi
    fi
fi

# All checks passed - allow the tool
log "INFO" "Allowing tool: $TOOL_NAME"
jq -n --arg tool "$TOOL_NAME" \
    --argjson ts "$(date +%s)" \
    '{
        decision: "allow",
        metadata: {
            tool: $tool,
            timestamp: $ts,
            checked: true
        }
    }'

# CRITICAL: Explicit exit to ensure clean return
exit 0
