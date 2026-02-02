#!/bin/bash
# Handler for /planner:ideas
# Pattern: <goal|roadmap-path> [--mode <full|focused>] [--rounds <number>] [--output <path>]

log_section "Ideas Handler"

GOAL=$(get_positional_arg "$ARGS" 0)
log_debug "GOAL" "$GOAL"
validate_required_arg "goal or roadmap-path" "$GOAL"

MODE=$(get_flag_value "$ARGS" "--mode")
if [[ -n "$MODE" ]]; then
  validate_one_of "mode" "$MODE" "full" "focused"
fi
log_debug "MODE" "${MODE:-full (default)}"

log_info "Arguments validated"
exit 0
