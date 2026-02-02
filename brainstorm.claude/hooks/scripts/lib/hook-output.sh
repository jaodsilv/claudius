#!/bin/bash
# Hook output formatting for brainstorm plugin

_escape_json() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | tr '\r' ' '
}

hook_output_block() {
  local reason="$1"
  local escaped=$(_escape_json "$reason")
  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "$escaped"}}
EOF
}

hook_output_context() {
  local context="$1"
  local escaped=$(_escape_json "$context")
  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "$escaped"}}
EOF
}
