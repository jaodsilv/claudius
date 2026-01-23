#!/bin/bash
# Handler for /gitx:remove-branch command
# Remove branch, block always
# --force: delete current branch by switching to default first

log_section "Remove-Branch Handler"
log_debug "ARGS" "$ARGS"

# Check for --force flag
FORCE=false
if [[ "$ARGS" =~ --force ]]; then
  FORCE=true
fi
log_debug "FORCE" "$FORCE"

# Extract branch name (first arg that's not a flag)
BRANCH=$(echo "$ARGS" | sed 's/--force//g; s/-f//g; s/-r//g; s/-ro//g' | xargs | cut -d' ' -f1)
if [[ -z "$BRANCH" ]]; then
  BRANCH=$(git -C "$WORKTREE" branch --show-current)
fi
log_debug "BRANCH" "$BRANCH"

# Check if branch exists
log_info "Checking if branch '$BRANCH' exists..."
if ! git -C "$WORKTREE" rev-parse --verify "$BRANCH" &>/dev/null; then
  log_error "Branch '$BRANCH' not found"
  log_exit 2 "branch not found"
  echo "Error: Branch '$BRANCH' not found" >&2
  exit 2
fi

# Check if trying to delete current branch
CURRENT=$(git -C "$WORKTREE" branch --show-current)
log_debug "CURRENT" "$CURRENT"

if [[ "$BRANCH" == "$CURRENT" ]]; then
  if [[ "$FORCE" == "false" ]]; then
    log_error "Cannot delete current branch without --force"
    log_exit 2 "current branch"
    echo "Error: Cannot delete current branch '$BRANCH'. Use --force to switch and delete." >&2
    exit 2
  fi
  # Switch to default branch first
  DEFAULT=$(git -C "$WORKTREE" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -z "$DEFAULT" ]]; then DEFAULT="main"; fi
  log_debug "DEFAULT_BRANCH" "$DEFAULT"
  log_info "Switching to $DEFAULT before deleting..."
  git -C "$WORKTREE" checkout "$DEFAULT"
fi

# Delete local
log_info "Deleting local branch..."
git -C "$WORKTREE" branch -D "$BRANCH" 2>&1 || true

# Delete remote (if -r or -ro flag)
if [[ "$ARGS" =~ -r[[:space:]]|-ro[[:space:]]|--force ]]; then
  log_info "Deleting remote branch..."
  git -C "$WORKTREE" push origin --delete "$BRANCH" 2>&1 || true
fi

log_info "Branch '$BRANCH' removed"
log_exit 0 "block with JSON"
echo "{\"decision\": \"block\", \"reason\": \"Branch '$BRANCH' removed.\"}"
exit 0
