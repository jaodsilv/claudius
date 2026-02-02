#!/bin/bash
# Handler for /gitx:update-pr command
# Validate PR exists

log_section "Update-PR Handler"

log_info "Checking if PR exists for branch '$CURRENT_BRANCH'..."
if ! gh pr view "$CURRENT_BRANCH" &>/dev/null; then
  log_error "No PR found for branch"
  log_exit 2 "no PR"
  echo "Error: No PR found for branch '$CURRENT_BRANCH'. Use /gitx:pr to create one." >&2
  exit 2
fi

log_info "PR exists, proceeding with update"
echo "PR exists. Proceeding with update."
log_exit 0 "proceed"
exit 0
