#!/bin/bash
# Handler for /gitx:rebase command
# Attempt rebase with sync, only run LLM if conflicts

log_section "Rebase Handler"
log_debug "ARGS" "$ARGS"

BASE="main"
NO_STASH=false
STASHED=false

if [[ "$ARGS" =~ --base[[:space:]]+([^[:space:]]+) ]]; then
  BASE="${BASH_REMATCH[1]}"
fi
if [[ "$ARGS" =~ --no-stash ]]; then
  NO_STASH=true
fi
log_debug "BASE" "$BASE"
log_debug "NO_STASH" "$NO_STASH"

CURRENT=$(git -C "$WORKTREE" branch --show-current)
log_debug "CURRENT" "$CURRENT"

# Check for dirty worktree
DIRTY_COUNT=$(git -C "$WORKTREE" status --porcelain | wc -l)
log_debug "DIRTY_COUNT" "$DIRTY_COUNT"

if [[ $DIRTY_COUNT -gt 0 ]]; then
  if [[ "$NO_STASH" == "true" ]]; then
    log_error "Working tree is dirty and --no-stash specified"
    log_exit 2 "dirty worktree"
    echo "Error: Working tree is dirty. Commit or stash changes first." >&2
    exit 2
  fi
  log_info "Stashing changes..."
  git -C "$WORKTREE" stash push -m "gitx:rebase auto-stash"
  STASHED=true
fi

# Sync base branch using worktree list to find main worktree
log_info "Syncing base branch..."
MAIN_WORKTREE=$(git worktree list --porcelain | grep -A1 "worktree" | grep -v "worktree" | head -1)
log_debug "MAIN_WORKTREE" "$MAIN_WORKTREE"

if [[ -n "$MAIN_WORKTREE" ]]; then
  git -C "$MAIN_WORKTREE" fetch origin "$BASE":"$BASE" 2>&1 || true
else
  git -C "$WORKTREE" fetch origin "$BASE":"$BASE" 2>&1 || true
fi

# Attempt rebase
log_info "Attempting rebase onto $BASE..."
if git -C "$WORKTREE" rebase "$BASE" 2>&1; then
  log_info "Rebase successful, pushing..."
  # Success - push and unstash
  git -C "$WORKTREE" push --force-with-lease
  if [[ "$STASHED" == "true" ]]; then
    log_info "Popping stash..."
    git -C "$WORKTREE" stash pop
  fi
  echo "Rebase successful. Pushed to remote."
  log_exit 2 "rebase successful - blocking"
  exit 2  # Block - no LLM needed
else
  log_warn "Rebase has conflicts, letting LLM handle"
  echo "Rebase has conflicts. Proceeding to conflict resolution."
  log_exit 0 "conflicts - LLM needed"
  exit 0
fi
