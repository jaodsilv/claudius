#!/bin/bash
# Handler for /gitx:pr command
# Validate PR doesn't already exist (creating new PR)

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "PR Handler"

# Use CURRENT_BRANCH from parent (exported by init())
log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

log_info "Checking if PR already exists for branch '$CURRENT_BRANCH'..."
if gh pr view "$CURRENT_BRANCH" &>/dev/null; then
  log_warn "PR already exists"
  log_exit 2 "PR exists"
  hook_output_block "PR already exists for branch '$CURRENT_BRANCH'. Use /gitx:update-pr instead."
  exit 2
fi

log_info "No existing PR, proceeding with creation"
hook_output_context "<worktree>$WORKTREE</worktree>"
echo "No existing PR. Proceeding with PR creation."
log_exit 0 "proceed"
exit 0
