#!/bin/bash
# Handler for /planner:roadmap
# Pattern: <goal> [--phases <number>] [--horizon <weeks|months>] [--output <path>]

log_section "Roadmap Handler"

GOAL=$(get_positional_arg "$ARGS" 0)
log_debug "GOAL" "$GOAL"
validate_required_arg "goal" "$GOAL"

HORIZON=$(get_flag_value "$ARGS" "--horizon")
if [[ -n "$HORIZON" ]]; then
  validate_one_of "horizon" "$HORIZON" "weeks" "months"
fi
log_debug "HORIZON" "${HORIZON:-months (default)}"

log_info "Arguments validated"
exit 0
