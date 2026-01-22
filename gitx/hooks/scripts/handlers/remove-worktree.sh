#!/bin/bash
# Handler for /gitx:remove-worktree command
# Remove worktree, block always
# --force: remove even if dirty

log_section "Remove-Worktree Handler"
log_debug "ARGS" "$ARGS"

# Check for --force flag
FORCE=false
if [[ "$ARGS" =~ --force ]]; then
  FORCE=true
fi
log_debug "FORCE" "$FORCE"

# Extract worktree path (first arg that's not a flag)
WT_PATH=$(echo "$ARGS" | sed 's/--force//g; s/-d//g; s/--delete//g' | xargs | cut -d' ' -f1)
if [[ -z "$WT_PATH" ]]; then
  WT_PATH="$WORKTREE"
fi
log_debug "WT_PATH" "$WT_PATH"

# Check if worktree exists
log_info "Checking if worktree '$WT_PATH' exists..."
if ! git worktree list | grep -q "$WT_PATH"; then
  log_error "Worktree '$WT_PATH' not found"
  log_exit 2 "worktree not found"
  echo "Error: Worktree '$WT_PATH' not found" >&2
  exit 2
fi

# Check if worktree is dirty (unless --force)
if [[ "$FORCE" == "false" ]]; then
  DIRTY_COUNT=$(git -C "$WT_PATH" status --porcelain 2>/dev/null | wc -l)
  log_debug "DIRTY_COUNT" "$DIRTY_COUNT"
  if [[ $DIRTY_COUNT -gt 0 ]]; then
    log_error "Worktree has uncommitted changes"
    log_exit 2 "dirty worktree"
    echo "Error: Worktree '$WT_PATH' has uncommitted changes. Use --force to remove anyway." >&2
    exit 2
  fi
fi

# Get branch before removing
BRANCH=$(git -C "$WT_PATH" branch --show-current 2>/dev/null || echo "")
log_debug "BRANCH" "$BRANCH"

# Remove worktree
log_info "Removing worktree..."
git worktree remove "$WT_PATH" --force

# Remove branch if specified
if [[ -n "$BRANCH" ]] && [[ "$ARGS" =~ -d|--delete ]]; then
  log_info "Deleting branch '$BRANCH'..."
  git branch -D "$BRANCH" 2>&1 || true
  git push origin --delete "$BRANCH" 2>&1 || true
fi

log_info "Worktree '$WT_PATH' removed"
echo "Worktree '$WT_PATH' removed."
log_exit 2 "block always"
exit 2  # Block always
