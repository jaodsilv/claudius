#!/bin/bash
# Common handler for review commands
# Patterns:
#   review-architecture: <goal|requirements-path> [--architecture-path <path>] [--mode <quick|thorough>]
#   review-plan: <plan-path> [--goal <goal>] [--mode <quick|thorough>]
#   review-prioritization: <goal|roadmap-path> [--prioritization-path <path>] [--mode <quick|thorough>]
#   review-requirements: <goal|roadmap-path> [--requirements-path <path>] [--mode <quick|thorough>]
#   review-roadmap: <goal> [--roadmap-path <path>] [--mode <quick|thorough>]

log_section "Review Handler ($COMMAND)"

# All review commands require the first positional argument
FIRST_ARG=$(get_positional_arg "$ARGS" 0)
log_debug "FIRST_ARG" "$FIRST_ARG"
validate_required_arg "goal or path" "$FIRST_ARG"

# Validate mode if provided (common to all review commands)
MODE=$(get_flag_value "$ARGS" "--mode")
if [[ -n "$MODE" ]]; then
  validate_one_of "mode" "$MODE" "quick" "thorough"
fi
log_debug "MODE" "${MODE:-thorough (default)}"

log_info "Arguments validated"
exit 0
