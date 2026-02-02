#!/bin/bash
# Handler for /planner:prioritize
# Pattern: <issue-numbers|ALL> [--framework <RICE|MoSCoW|WeightedScoring>] [--output <path>]

log_section "Prioritize Handler"

ISSUES=$(get_positional_arg "$ARGS" 0)
log_debug "ISSUES" "$ISSUES"
validate_required_arg "issue-numbers or ALL" "$ISSUES"

FRAMEWORK=$(get_flag_value "$ARGS" "--framework")
if [[ -n "$FRAMEWORK" ]]; then
  validate_one_of "framework" "$FRAMEWORK" "RICE" "MoSCoW" "WeightedScoring"
fi
log_debug "FRAMEWORK" "${FRAMEWORK:-RICE (default)}"

log_info "Arguments validated"
exit 0
