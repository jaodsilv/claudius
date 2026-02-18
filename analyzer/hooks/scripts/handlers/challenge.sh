#!/bin/bash
# Handler for /analyzer:challenge command
# Emits worktree context for the challenge skill

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Challenge Handler"

log_debug "WORKTREE" "$WORKTREE"
hook_output_context "<worktree>$WORKTREE</worktree>"
log_exit 0 "proceed"
exit 0
