#!/bin/bash
# Handler for /review-loop:start-loop skill
# Validates worktree and outputs it as additional context

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Start-Loop Handler"

log_debug "WORKTREE" "$WORKTREE"

# Validate worktree exists
if [[ ! -d "$WORKTREE" ]]; then
  log_error "Worktree directory does not exist: $WORKTREE"
  log_exit 2 "worktree not found"
  hook_output_block "Worktree directory does not exist: $WORKTREE"
  exit 0
fi

log_info "Worktree validated: $WORKTREE"
log_exit 0 "proceed"

# Output worktree as additional context
hook_output_context "<worktree>$WORKTREE</worktree>"
exit 0
