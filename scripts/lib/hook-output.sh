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

# ---------------------------------------------------------------------------
# Content injection strategy: inject inline vs explicit Read instruction
# ---------------------------------------------------------------------------
# Decision matrix (Cross-Model):
#   Small  (<500 tok):   Always inject
#   Medium (500-10K tok): Inject for Haiku, explicit Read for Opus/Sonnet
#   Large  (10K+ tok):   Always explicit Read (with line ranges for Haiku)
#
# Usage:
#   inject_or_read <filepath> <xml_tag> [model]
#     model: "opus", "sonnet", or "haiku" (default: "sonnet")
#
# Output: XML-wrapped content (inject) or read instruction (explicit read)
#   Inject:  <tag>file content</tag>
#   Read:    <tag source="file" strategy="explicit-read">Read the file at: path</tag>
# ---------------------------------------------------------------------------
inject_or_read() {
  local filepath="$1"
  local xml_tag="$2"
  local model="${3:-sonnet}"

  # Locate count-tokens.py relative to this script
  local _lib_dir
  _lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local count_tokens_script="$_lib_dir/count-tokens.py"

  # Estimate tokens (fallback to inject if script missing or fails)
  local tokens=0
  if [[ -f "$count_tokens_script" ]]; then
    tokens=$(python3 "$count_tokens_script" --filepath "$filepath" --porcelain 2>/dev/null || echo "0")
  fi

  # Determine strategy from decision matrix
  local strategy="inject"
  if [[ "$tokens" -ge 10000 ]]; then
    strategy="read"
  elif [[ "$tokens" -ge 500 ]]; then
    if [[ "$model" != "haiku" ]]; then
      strategy="read"
    fi
  fi

  if [[ "$strategy" == "inject" ]]; then
    local content
    content=$(cat "$filepath")
    printf '<%s>\n%s\n</%s>' "$xml_tag" "$content" "$xml_tag"
  else
    if [[ "$model" == "haiku" ]]; then
      printf '<%s source="file" strategy="explicit-read-with-ranges">\nRead the file at: %s\nThe file is large (~%d tokens). Read it in sections using line ranges.\n</%s>' \
        "$xml_tag" "$filepath" "$tokens" "$xml_tag"
    else
      printf '<%s source="file" strategy="explicit-read">\nRead the file at: %s\n</%s>' \
        "$xml_tag" "$filepath" "$xml_tag"
    fi
  fi
}
