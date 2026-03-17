#!/bin/bash
# Handler for /planner:gather-requirements
# Pattern: <goal> [--use-brainstorm] [--depth <shallow|normal|deep>] [--output <path>]

log_section "Gather-Requirements Handler"

GOAL=$(get_positional_arg "$ARGS" 0)
log_debug "GOAL" "$GOAL"
validate_required_arg "goal" "$GOAL"

DEPTH=$(get_flag_value "$ARGS" "--depth")
if [[ -n "$DEPTH" ]]; then
  validate_one_of "depth" "$DEPTH" "shallow" "normal" "deep"
fi
log_debug "DEPTH" "${DEPTH:-normal (default)}"

log_info "Arguments validated"
exit 0
