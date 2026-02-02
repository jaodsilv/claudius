#!/bin/bash
# Handler for /brainstorm:export
# Validate required session path and optional format

log_section "Export Handler"

# Pattern: ([--session-path] <path>) [--format <markdown|pdf|html>]

# Get path from --session-path flag or first positional arg
SESSION_PATH=$(get_flag_value "$ARGS" "--session-path")
if [[ -z "$SESSION_PATH" ]]; then
  SESSION_PATH=$(get_positional_arg "$ARGS" 0)
fi
log_debug "SESSION_PATH" "$SESSION_PATH"

# Validate required path
validate_required_arg "session path" "$SESSION_PATH"

# Validate format if provided
FORMAT=$(get_flag_value "$ARGS" "--format")
if [[ -n "$FORMAT" ]]; then
  validate_one_of "format" "$FORMAT" "markdown" "pdf" "html"
fi
log_debug "FORMAT" "${FORMAT:-markdown (default)}"

log_info "Arguments validated"
exit 0
