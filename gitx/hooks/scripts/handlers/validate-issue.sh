#!/bin/bash
# Handler for /gitx:comment-to-issue and /gitx:fix-issue commands
# Validate issue exists

log_section "Validate-Issue Handler"
log_debug "ARGS" "$ARGS"

# Extract issue number from args
ISSUE_NUM=""
if [[ "$ARGS" =~ ^([0-9]+) ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
elif [[ "$ARGS" =~ \#([0-9]+) ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
fi
log_debug "ISSUE_NUM" "$ISSUE_NUM"

if [[ -z "$ISSUE_NUM" ]]; then
  log_error "No issue number provided"
  log_exit 2 "no issue number"
  echo "Error: No issue number provided" >&2
  exit 2
fi

# Check issue exists
log_info "Checking if issue #$ISSUE_NUM exists..."
if ! gh issue view "$ISSUE_NUM" &>/dev/null; then
  log_error "Issue #$ISSUE_NUM not found"
  log_exit 2 "issue not found"
  echo "Error: Issue #$ISSUE_NUM not found" >&2
  exit 2
fi

log_info "Issue #$ISSUE_NUM validated"
echo "Issue #$ISSUE_NUM exists. Proceeding."
log_exit 0 "issue validated"
exit 0
