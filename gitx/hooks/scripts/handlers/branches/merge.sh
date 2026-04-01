#!/bin/bash
# Handler for /gitx:merge command
# Attempt merge with sync, only run LLM if conflicts

# Source libraries for validation and output
source "$SCRIPTS_DIR/lib/args-validator.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"

log_section "Merge Handler"
log_debug "ARGS" "$ARGS"

# Use get_flag_value or regex for --base
BASE=$(get_flag_value "$ARGS" "--base")
[[ -z "$BASE" ]] && BASE="main"
log_debug "BASE" "$BASE"

# Use CURRENT_BRANCH from parent (exported by init())
log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

# Verify branches exist
log_info "Verifying branches exist..."
if ! git -C "$WORKTREE" rev-parse --verify "$BASE" &>/dev/null; then
  log_error "Base branch '$BASE' not found"
  log_exit 2 "base branch not found"
  echo "Error: Base branch '$BASE' not found" >&2
  exit 2
fi

if ! git -C "$WORKTREE" rev-parse --verify "$CURRENT_BRANCH" &>/dev/null; then
  log_error "Current branch '$CURRENT_BRANCH' not found"
  log_exit 2 "current branch not found"
  echo "Error: Current branch '$CURRENT_BRANCH' not found" >&2
  exit 2
fi
log_info "Both branches exist"

# Sync both branches
log_info "Fetching latest from origin..."
git -C "$WORKTREE" fetch origin "$BASE":"$BASE" 2>&1 || true
git -C "$WORKTREE" fetch origin "$CURRENT_BRANCH":"$CURRENT_BRANCH" 2>&1 || true

# Attempt merge
log_info "Attempting merge of $BASE into $CURRENT_BRANCH..."
if git -C "$WORKTREE" merge "$BASE" --no-edit 2>&1; then
  log_info "Merge successful, no conflicts"
  log_exit 0 "merge successful - block"
  hook_output_block "Merge successful. $BASE merged into $CURRENT_BRANCH."
  exit 0
else
  log_warn "Merge has conflicts, letting LLM handle"
  echo "Merge has conflicts. Proceeding to conflict resolution."
  log_exit 0 "conflicts - LLM needed"
  exit 0
fi
