#!/bin/bash
# Handler for /gitx:remove-branch command
# Remove branch, block always
# --force: delete current branch by switching to default first

# Source args validator and hook output
source "$SCRIPTS_DIR/lib/args-validator.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"

log_section "Remove-Branch Handler"
log_debug "ARGS" "$ARGS"

# Validate mutually exclusive remote flags
# Pattern: [-r or --remove-remote | -ro or --remote-only]
validate_mutually_exclusive "$ARGS" "-r or --remove-remote" "-ro or --remote-only"

# Check for --force flag using has_flag
FORCE=false
if has_flag "$ARGS" "-f or --force"; then
  FORCE=true
fi
log_debug "FORCE" "$FORCE"

# Extract branch name using get_positional_arg
BRANCH=$(get_positional_arg "$ARGS")
if [[ -z "$BRANCH" ]]; then
  # Default to current branch
  BRANCH="$CURRENT_BRANCH"
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

# Use CURRENT_BRANCH from parent (exported by init())
log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

if [[ "$BRANCH" == "$CURRENT_BRANCH" ]]; then
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

# Delete remote (if -r or -ro flag) using has_flag
if has_flag "$ARGS" "-r or --remove-remote" || has_flag "$ARGS" "-ro or --remote-only"; then
  log_info "Deleting remote branch..."
  git -C "$WORKTREE" push origin --delete "$BRANCH" 2>&1 || true
fi

log_info "Branch '$BRANCH' removed"
log_exit 0 "block"
hook_output_block "Branch '$BRANCH' removed."
exit 0
