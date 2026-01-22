#!/bin/bash
# Gets the default branch name and its worktree path
# Usage: get-default-branch.sh
# Output: YAML with defaultBranch and defaultBranchPath

set -uo pipefail

# Get the default branch name from GitHub
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>&1)
if [[ -z "$DEFAULT_BRANCH" ]] || [[ "$DEFAULT_BRANCH" == "null" ]]; then
  echo "error: Could not determine default branch" >&2
  exit 1
fi

# Get the worktree path for the default branch
# The worktree list format is: /path/to/worktree  hash [branch]
WORKTREE_PATH=$(git worktree list | grep -E "\[$DEFAULT_BRANCH\]$" | awk '{print $1}')

# If no dedicated worktree, check if we're on the default branch in main worktree
if [[ -z "$WORKTREE_PATH" ]]; then
  # Get the main worktree (first line, which is the main working tree)
  MAIN_WORKTREE=$(git worktree list | head -1 | awk '{print $1}')
  MAIN_BRANCH=$(git -C "$MAIN_WORKTREE" branch --show-current 2>/dev/null)

  if [[ "$MAIN_BRANCH" == "$DEFAULT_BRANCH" ]]; then
    WORKTREE_PATH="$MAIN_WORKTREE"
  fi
fi

# Output as YAML
echo "defaultBranch: $DEFAULT_BRANCH"
if [[ -n "$WORKTREE_PATH" ]]; then
  echo "defaultBranchPath: $WORKTREE_PATH"
else
  echo "defaultBranchPath: null"
fi
