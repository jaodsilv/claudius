#!/bin/bash
# Synchronizes a git branch with remote
# Usage: sync-branch.sh [worktree_path]
# Output: JSON with sync results

set -uo pipefail

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# Get worktree path from argument or use current directory
WORKTREE="${1:-.}"
WORKTREE=$(convert_path "$WORKTREE")

# Resolve to absolute path if relative
if [[ "$WORKTREE" == "." ]] || [[ -z "$WORKTREE" ]]; then
  WORKTREE=$(convert_path "$(pwd)")
elif [[ ! "$WORKTREE" = /* ]]; then
  WORKTREE=$(convert_path "$(cd "$WORKTREE" && pwd)")
fi

# Track state
STASHED=false
STASH_CONFLICT=false
SYNC_SUCCESS=true
ERROR_MSG=""

# Pre-flight: Check not in detached HEAD
BRANCH=$(git -C "$WORKTREE" branch --show-current 2>&1)
if [[ -z "$BRANCH" ]]; then
  echo '{"success": false, "error": "detached_head", "message": "Cannot sync: in detached HEAD state"}'
  exit 1
fi

# Step 1: Fetch from origin
if ! git -C "$WORKTREE" fetch origin 2>&1; then
  echo '{"success": false, "error": "fetch_failed", "message": "Failed to fetch from origin"}'
  exit 1
fi

# Step 2: Check if dirty and stash if needed
DIRTY_STATUS=$(git -C "$WORKTREE" status --porcelain 2>&1)
if [[ -n "$DIRTY_STATUS" ]]; then
  if git -C "$WORKTREE" stash --include-untracked 2>&1; then
    STASHED=true
  else
    echo '{"success": false, "error": "stash_failed", "message": "Failed to stash changes"}'
    exit 1
  fi
fi

# Step 3: Pull with rebase
PULL_OUTPUT=$(git -C "$WORKTREE" pull --rebase 2>&1)
PULL_EXIT=$?
if [[ $PULL_EXIT -ne 0 ]]; then
  # Check if it's a rebase conflict
  if echo "$PULL_OUTPUT" | grep -q "CONFLICT\|rebase"; then
    ERROR_MSG="Rebase conflict detected. Resolve with: git rebase --continue or git rebase --abort"
  else
    ERROR_MSG="Pull failed: $PULL_OUTPUT"
  fi
  SYNC_SUCCESS=false
fi

# Step 4: Push (only if pull succeeded)
if [[ "$SYNC_SUCCESS" == "true" ]]; then
  PUSH_OUTPUT=$(git -C "$WORKTREE" push 2>&1)
  PUSH_EXIT=$?
  if [[ $PUSH_EXIT -ne 0 ]]; then
    # Check if it's just "nothing to push" which is fine
    if ! echo "$PUSH_OUTPUT" | grep -q "Everything up-to-date"; then
      ERROR_MSG="Push failed: $PUSH_OUTPUT"
      SYNC_SUCCESS=false
    fi
  fi
fi

# Step 5: Pop stash if we stashed
if [[ "$STASHED" == "true" ]]; then
  STASH_OUTPUT=$(git -C "$WORKTREE" stash pop 2>&1)
  STASH_EXIT=$?
  if [[ $STASH_EXIT -ne 0 ]]; then
    STASH_CONFLICT=true
    if [[ "$SYNC_SUCCESS" == "true" ]]; then
      ERROR_MSG="Stash pop had conflicts. Resolve manually."
    else
      ERROR_MSG="$ERROR_MSG; Also: stash pop had conflicts."
    fi
  fi
fi

# Output result as JSON
if [[ "$SYNC_SUCCESS" == "true" ]] && [[ "$STASH_CONFLICT" == "false" ]]; then
  echo "{\"success\": true, \"branch\": \"$BRANCH\", \"stashed\": $STASHED, \"worktree\": \"$WORKTREE\"}"
else
  # Escape quotes in error message for JSON
  ESCAPED_MSG=$(echo "$ERROR_MSG" | sed 's/"/\\"/g' | tr '\n' ' ')
  echo "{\"success\": false, \"branch\": \"$BRANCH\", \"stashed\": $STASHED, \"stash_conflict\": $STASH_CONFLICT, \"error\": \"$ESCAPED_MSG\"}"
  exit 1
fi
