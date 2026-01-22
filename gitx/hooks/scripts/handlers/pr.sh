#!/bin/bash
# Handler for /gitx:pr command
# Validate PR doesn't already exist (creating new PR)

log_section "PR Handler"

CURRENT=$(git -C "$WORKTREE" branch --show-current)
log_debug "CURRENT_BRANCH" "$CURRENT"

log_info "Checking if PR already exists for branch '$CURRENT'..."
if gh pr view "$CURRENT" &>/dev/null; then
  log_warn "PR already exists"
  log_exit 2 "PR exists"
  echo "PR already exists for branch '$CURRENT'. Use /gitx:update-pr instead." >&2
  exit 2
fi

log_info "No existing PR, proceeding with creation"
echo "No existing PR. Proceeding with PR creation."
log_exit 0 "proceed"
exit 0
