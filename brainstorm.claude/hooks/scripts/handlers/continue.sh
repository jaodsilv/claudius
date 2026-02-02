#!/bin/bash
# Handler for /brainstorm:continue
# Validate required session path

log_section "Continue Handler"

# Pattern: ([--session-path] <path>)

# Get path from --session-path flag or first positional arg
SESSION_PATH=$(get_flag_value "$ARGS" "--session-path")
if [[ -z "$SESSION_PATH" ]]; then
  SESSION_PATH=$(get_positional_arg "$ARGS" 0)
fi
log_debug "SESSION_PATH" "$SESSION_PATH"

# Validate required path
validate_required_arg "session path" "$SESSION_PATH"

log_info "Arguments validated"
exit 0
