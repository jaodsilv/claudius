#!/bin/bash
# Shared library for hook output formatting
# Supports UserPromptSubmit, PreToolUse, PostToolUse, and Stop hook events
#
# Environment variable set by wrapper:
#   HOOK_EVENT_TYPE - "UserPromptSubmit", "PreToolUse", "PostToolUse", or "Stop"
#
# Usage:
#   source "$SCRIPTS_DIR/lib/hook-output.sh"
#   hook_output_block "reason to block"
#   hook_output_context "additional context"

# Escape string for JSON (handles backslashes, quotes, newlines)
# Exported as json_escape for use by handlers
_escape_json() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | tr '\r' ' '
}
json_escape() { _escape_json "$@"; }

# Output a blocking response (prevents the tool/prompt from executing)
# For PreToolUse: uses permissionDecision: "deny"
# For PostToolUse: uses decision: "block" with hookSpecificOutput
# For Stop/UserPromptSubmit: uses decision: "block"
hook_output_block() {
  local reason="$1"
  local escaped=$(_escape_json "$reason")

  case "${HOOK_EVENT_TYPE:-}" in
    PreToolUse)
      cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "$escaped"}}
EOF
      ;;
    PostToolUse)
      cat <<EOF
{"decision": "block", "reason": "$escaped", "hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "$escaped"}}
EOF
      ;;
    Stop|UserPromptSubmit|*)
      cat <<EOF
{"decision": "block", "reason": "$escaped"}
EOF
      ;;
  esac
}

hook_output_ask_user() {
  local reason="$1"
  local escaped=$(_escape_json "$reason")

  case "${HOOK_EVENT_TYPE:-}" in
    PreToolUse)
      cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "$escaped"}}
EOF
      ;;
  esac
}

# Output context to be injected into the tool/prompt
# Works the same for both hook types (additionalContext is shared)
hook_output_context() {
  local context="$1"
  local escaped=$(_escape_json "$context")
  local event_type="${HOOK_EVENT_TYPE:-UserPromptSubmit}"

  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "$event_type", "additionalContext": "$escaped"}}
EOF
}

hook_output_system_message() {
  local reason="$1"
  local escaped=$(_escape_json "$reason")

  cat <<EOF
    {"systemMessage": "$escaped"}
EOF
}

hook_output_status_ok() {
  cat <<EOF
    {"status": "ok"}
EOF
}
