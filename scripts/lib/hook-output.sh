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
# Per-model injection ceilings (tokens)
# Content below the ceiling is injected inline; above triggers read strategies
# ---------------------------------------------------------------------------
readonly OPUS_INJECT_CEILING=4000
readonly SONNET_INJECT_CEILING=6000
readonly HAIKU_INJECT_CEILING=8000
readonly TARGETED_READ_CEILING=20000
readonly SPLIT_TASK_CEILING=40000

# ---------------------------------------------------------------------------
# Content injection strategy: inject inline vs explicit Read instruction
# ---------------------------------------------------------------------------
# Decision matrix (per-model ceilings):
#   Model   Inject       Explicit-Read      Targeted-Read     Split-Task
#   opus    < 4K tok     4K–20K tok         20K–40K tok       40K+ tok
#   sonnet  < 6K tok     6K–20K tok         20K–40K tok       40K+ tok
#   haiku   < 8K tok     8K–20K tok         20K–40K tok       40K+ tok
#
# Usage:
#   inject_or_read <filepath> <xml_tag> [model]
#     model: "opus", "sonnet", or "haiku" (default: "sonnet")
#
# Output per strategy:
#   inject:        <tag>file content</tag>
#   explicit-read: <tag source="file" strategy="explicit-read">Read file at: path</tag>
#   targeted-read: <tag source="file" strategy="targeted-read">Read file at: path (use offset/limit)</tag>
#   split-task:    <tag source="file" strategy="split-task">File too large, split work</tag>
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

  # Determine per-model injection ceiling
  local ceiling
  case "$model" in
    opus)   ceiling=$OPUS_INJECT_CEILING ;;
    haiku)  ceiling=$HAIKU_INJECT_CEILING ;;
    *)      ceiling=$SONNET_INJECT_CEILING ;;  # default: sonnet
  esac

  # Determine strategy from decision matrix
  local strategy="inject"
  if [[ "$tokens" -ge "$SPLIT_TASK_CEILING" ]]; then
    strategy="split-task"
  elif [[ "$tokens" -ge "$TARGETED_READ_CEILING" ]]; then
    strategy="targeted-read"
  elif [[ "$tokens" -ge "$ceiling" ]]; then
    strategy="explicit-read"
  fi

  case "$strategy" in
    inject)
      local content
      content=$(cat "$filepath")
      printf '<%s>\n%s\n</%s>' "$xml_tag" "$content" "$xml_tag"
      ;;
    explicit-read)
      printf '<%s source="file" strategy="explicit-read">\nRead the file at: %s\n</%s>' \
        "$xml_tag" "$filepath" "$xml_tag"
      ;;
    targeted-read)
      printf '<%s source="file" strategy="targeted-read">\nRead the file at: %s\nThe file is large (~%d tokens). Read it in sections using offset and limit parameters (500 lines per section).\n</%s>' \
        "$xml_tag" "$filepath" "$tokens" "$xml_tag"
      ;;
    split-task)
      printf '<%s source="file" strategy="split-task">\nThe file at: %s is very large (~%d tokens). Consider splitting into smaller tasks or pre-extracting the relevant sections before processing.\n</%s>' \
        "$xml_tag" "$filepath" "$tokens" "$xml_tag"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Content injection for string data (e.g., git diffs)
# Same strategy logic as inject_or_read but accepts content string
# ---------------------------------------------------------------------------
# Usage:
#   inject_or_read_content <content> <xml_tag> [model] [content_type]
#     model: "opus", "sonnet", or "haiku" (default: "sonnet")
#     content_type: "code", "prose", "conf" (default: "code")
# ---------------------------------------------------------------------------
inject_or_read_content() {
  local content="$1"
  local xml_tag="$2"
  local model="${3:-sonnet}"
  local content_type="${4:-code}"

  # Locate count-tokens.py relative to this script
  local _lib_dir
  _lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local count_tokens_script="$_lib_dir/count-tokens.py"

  # Estimate tokens (fallback to inject if script missing or fails)
  local tokens=0
  if [[ -f "$count_tokens_script" ]]; then
    tokens=$(printf '%s' "$content" | python3 "$count_tokens_script" --stdin --force-content-type "$content_type" --porcelain 2>/dev/null || echo "0")
  fi

  # Determine per-model injection ceiling
  local ceiling
  case "$model" in
    opus)   ceiling=$OPUS_INJECT_CEILING ;;
    haiku)  ceiling=$HAIKU_INJECT_CEILING ;;
    *)      ceiling=$SONNET_INJECT_CEILING ;;
  esac

  # Determine strategy
  local strategy="inject"
  if [[ "$tokens" -ge "$SPLIT_TASK_CEILING" ]]; then
    strategy="split-task"
  elif [[ "$tokens" -ge "$TARGETED_READ_CEILING" ]]; then
    strategy="targeted-read"
  elif [[ "$tokens" -ge "$ceiling" ]]; then
    strategy="explicit-read"
  fi

  case "$strategy" in
    inject)
      printf '<%s>\n%s\n</%s>' "$xml_tag" "$content" "$xml_tag"
      ;;
    explicit-read|targeted-read|split-task)
      # Write content to temp file for agent to read
      local tmpfile
      tmpfile=$(mktemp "${TMPDIR:-/tmp}/hook-content-XXXXXX.txt")
      # NOTE: No cleanup trap. The temp file must persist after this hook exits
      # because the agent reads it asynchronously. OS tmp cleanup handles removal.
      printf '%s' "$content" > "$tmpfile"

      if [[ "$strategy" == "explicit-read" ]]; then
        printf '<%s source="file" strategy="explicit-read">\nRead the file at: %s\n</%s>' \
          "$xml_tag" "$tmpfile" "$xml_tag"
      elif [[ "$strategy" == "targeted-read" ]]; then
        printf '<%s source="file" strategy="targeted-read">\nRead the file at: %s\nThe content is large (~%d tokens). Read it in sections using offset and limit parameters (500 lines per section).\n</%s>' \
          "$xml_tag" "$tmpfile" "$tokens" "$xml_tag"
      else
        printf '<%s source="file" strategy="split-task">\nThe content at: %s is very large (~%d tokens). Consider splitting into smaller tasks or pre-extracting the relevant sections before processing.\n</%s>' \
          "$xml_tag" "$tmpfile" "$tokens" "$xml_tag"
      fi
      ;;
  esac
}
