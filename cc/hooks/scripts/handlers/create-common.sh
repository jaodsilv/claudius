#!/bin/bash
# Common handler for create-* commands
# Patterns:
#   create-command: <command-name> [--plugin <plugin-path>]
#   create-skill: <skill-name> [--plugin <plugin-path>]
#   create-orchestration: <orchestration-name> [--plugin <plugin-path>]
#   create-output-style: <style-name> [--plugin <plugin-path>]

log_section "Create Handler ($COMMAND)"

# All create commands require the first positional argument (name)
NAME=$(get_positional_arg "$ARGS" 0)
log_debug "NAME" "$NAME"
validate_required_arg "name" "$NAME"

log_info "Arguments validated"
log_exit 0 "proceed"
exit 0
