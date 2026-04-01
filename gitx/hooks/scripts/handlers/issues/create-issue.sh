#!/bin/bash
# Handler for /gitx:create-issue command
# Validate required description argument

# Source args validator
source "$SCRIPTS_DIR/lib/args-validator.sh"

log_section "Create-Issue Handler"
log_debug "ARGS" "$ARGS"

# Extract description (first positional argument)
DESCRIPTION=$(get_positional_arg "$ARGS" 0)
log_debug "DESCRIPTION" "$DESCRIPTION"

# Validate required description
# Pattern: <description> [-l <label>+] [-a <assignee>] [-t <template>] [-m <milestone>] [--no-preview]
validate_required_arg "description" "$DESCRIPTION"

log_info "Description validated: $DESCRIPTION"
log_exit 0 "proceed"
exit 0
