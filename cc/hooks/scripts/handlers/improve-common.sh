#!/bin/bash
# Common handler for improve-* commands
# Patterns:
#   improve-agent: <agent-path> [--focus "<aspect>"]
#   improve-command: <command-path> [--focus "<aspect>"]
#   improve-skill: <skill-path> [--focus "<aspect>"]
#   improve-plugin: <plugin-path> [--focus "<aspect>"]
#   improve-orchestration: <orchestration-path> [--focus "<aspect>"]
#   improve-output-style: <output-style-path> [--focus "<aspect>"]

log_section "Improve Handler ($COMMAND)"

# All improve commands require the first positional argument (path)
PATH_ARG=$(get_positional_arg "$ARGS" 0)
log_debug "PATH_ARG" "$PATH_ARG"
validate_required_arg "path" "$PATH_ARG"

log_info "Arguments validated"
log_exit 0 "proceed"
exit 0
