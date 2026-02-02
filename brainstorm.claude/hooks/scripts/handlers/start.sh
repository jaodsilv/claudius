#!/bin/bash
# Handler for /brainstorm:start
# Validate required topic and optional depth

log_section "Start Handler"

# Pattern: <topic> [--depth <shallow|normal|deep>] [--output-path <path>]

# Get topic (required first positional arg)
TOPIC=$(get_positional_arg "$ARGS" 0)
log_debug "TOPIC" "$TOPIC"

# Validate required topic
validate_required_arg "topic" "$TOPIC"

# Validate depth if provided
DEPTH=$(get_flag_value "$ARGS" "--depth")
if [[ -n "$DEPTH" ]]; then
  validate_one_of "depth" "$DEPTH" "shallow" "normal" "deep"
fi
log_debug "DEPTH" "${DEPTH:-normal (default)}"

log_info "Arguments validated"
exit 0
