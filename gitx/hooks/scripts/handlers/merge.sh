#!/bin/bash
# Handler for /gitx:merge command
# Attempt merge with sync, only run LLM if conflicts

log_section "Merge Handler"
log_debug "ARGS" "$ARGS"

BASE="main"
if [[ "$ARGS" =~ --base[[:space:]]+([^[:space:]]+) ]]; then
  BASE="${BASH_REMATCH[1]}"
fi
log_debug "BASE" "$BASE"

CURRENT=$(git -C "$WORKTREE" branch --show-current)
log_debug "CURRENT" "$CURRENT"

# Verify branches exist
log_info "Verifying branches exist..."
if ! git -C "$WORKTREE" rev-parse --verify "$BASE" &>/dev/null; then
  log_error "Base branch '$BASE' not found"
  log_exit 2 "base branch not found"
  echo "Error: Base branch '$BASE' not found" >&2
  exit 2
fi

if ! git -C "$WORKTREE" rev-parse --verify "$CURRENT" &>/dev/null; then
  log_error "Current branch '$CURRENT' not found"
  log_exit 2 "current branch not found"
  echo "Error: Current branch '$CURRENT' not found" >&2
  exit 2
fi
log_info "Both branches exist"

# Sync both branches
log_info "Fetching latest from origin..."
git -C "$WORKTREE" fetch origin "$BASE":"$BASE" 2>&1 || true
git -C "$WORKTREE" fetch origin "$CURRENT":"$CURRENT" 2>&1 || true

# Attempt merge
log_info "Attempting merge of $BASE into $CURRENT..."
if git -C "$WORKTREE" merge "$BASE" --no-edit 2>&1; then
  log_info "Merge successful, no conflicts"
  log_exit 0 "merge successful - block with JSON"
  echo "{\"decision\": \"block\", \"reason\": \"Merge successful. $BASE merged into $CURRENT.\"}"
  exit 0
else
  log_warn "Merge has conflicts, letting LLM handle"
  echo "Merge has conflicts. Proceeding to conflict resolution."
  log_exit 0 "conflicts - LLM needed"
  exit 0
fi
