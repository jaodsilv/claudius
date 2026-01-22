#!/bin/bash
# Performs rebase or merge operations with auto-stash and conflict detection
# Usage: rebase-merge-common.sh <mode> [options]
# Mode: rebase | merge
# Options:
#   --base <branch>     Base branch to rebase/merge onto (default: default branch)
#   --no-stash          Fail if working tree is dirty instead of auto-stashing
#   --force             Skip confirmation prompts
#   --worktree <path>   Worktree path to operate in (default: current directory)
#
# Exit codes:
#   0: Success, no conflicts
#   1: Conflicts detected (needs LLM resolution)
#   2: Error (sync failed, bad arguments, etc.)
#
# Output: JSON with operation results

set -uo pipefail

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# JSON output helpers
json_success() {
  local mode="$1" base="$2" feature="$3" commits="$4" stashed="$5"
  echo "{\"success\": true, \"mode\": \"$mode\", \"base\": \"$base\", \"feature\": \"$feature\", \"commits_processed\": $commits, \"stashed\": $stashed, \"conflicts\": false}"
}

json_conflicts() {
  local mode="$1" base="$2" feature="$3" files="$4" stashed="$5"
  # Escape files for JSON
  local escaped_files
  escaped_files=$(echo "$files" | tr '\n' ',' | sed 's/,$//' | sed 's/"/\\"/g')
  echo "{\"success\": false, \"mode\": \"$mode\", \"base\": \"$base\", \"feature\": \"$feature\", \"conflicts\": true, \"conflict_files\": [\"${escaped_files//,/\", \"}\"], \"stashed\": $stashed}"
}

json_error() {
  local code="$1" message="$2"
  local escaped_msg
  escaped_msg=$(echo "$message" | sed 's/"/\\"/g' | tr '\n' ' ')
  echo "{\"success\": false, \"error\": \"$code\", \"message\": \"$escaped_msg\"}"
  exit 2
}

# Parse arguments
MODE=""
BASE_BRANCH=""
NO_STASH=false
FORCE=false
WORKTREE="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    rebase|merge)
      MODE="$1"
      shift
      ;;
    --base)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --no-stash)
      NO_STASH=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --worktree)
      WORKTREE="$2"
      shift 2
      ;;
    *)
      json_error "invalid_argument" "Unknown argument: $1"
      ;;
  esac
done

# Validate mode
if [[ -z "$MODE" ]]; then
  json_error "missing_mode" "Mode required: rebase or merge"
fi

# Convert and validate worktree path
WORKTREE=$(convert_path "$WORKTREE")
if [[ "$WORKTREE" == "." ]]; then
  WORKTREE=$(convert_path "$(pwd)")
elif [[ ! "$WORKTREE" = /* ]]; then
  WORKTREE=$(convert_path "$(cd "$WORKTREE" && pwd)")
fi

if [[ ! -d "$WORKTREE" ]]; then
  json_error "invalid_worktree" "Worktree path does not exist: $WORKTREE"
fi

# Get current branch
FEATURE_BRANCH=$(git -C "$WORKTREE" branch --show-current 2>&1)
if [[ -z "$FEATURE_BRANCH" ]]; then
  json_error "detached_head" "Cannot $MODE: in detached HEAD state"
fi

# Get default branch if not specified
if [[ -z "$BASE_BRANCH" ]]; then
  DEFAULT_BRANCH_SCRIPT="$PLUGIN_ROOT/skills/getting-default-branch/scripts/get-default-branch.sh"
  if [[ -f "$DEFAULT_BRANCH_SCRIPT" ]]; then
    DEFAULT_INFO=$("$DEFAULT_BRANCH_SCRIPT" 2>&1)
    BASE_BRANCH=$(echo "$DEFAULT_INFO" | grep "^defaultBranch:" | cut -d' ' -f2)
    BASE_PATH=$(echo "$DEFAULT_INFO" | grep "^defaultBranchPath:" | cut -d' ' -f2)
  fi

  if [[ -z "$BASE_BRANCH" ]]; then
    # Fallback: try common defaults
    if git -C "$WORKTREE" show-ref --verify --quiet "refs/heads/main"; then
      BASE_BRANCH="main"
    elif git -C "$WORKTREE" show-ref --verify --quiet "refs/heads/master"; then
      BASE_BRANCH="master"
    else
      json_error "no_base_branch" "Could not determine base branch. Use --base to specify."
    fi
  fi
fi

# Check if base branch exists
if ! git -C "$WORKTREE" show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
  json_error "base_not_found" "Base branch '$BASE_BRANCH' does not exist locally"
fi

# Same branch check
if [[ "$FEATURE_BRANCH" == "$BASE_BRANCH" ]]; then
  json_error "same_branch" "Cannot $MODE: current branch is the same as base branch ($BASE_BRANCH)"
fi

# Track state
STASHED=false

# Step 1: Check working tree status
DIRTY_STATUS=$(git -C "$WORKTREE" status --porcelain 2>&1)
if [[ -n "$DIRTY_STATUS" ]]; then
  if [[ "$NO_STASH" == "true" ]]; then
    json_error "dirty_worktree" "Working tree has uncommitted changes. Commit or stash them first."
  fi

  # Auto-stash
  if ! git -C "$WORKTREE" stash push -m "gitx: pre-$MODE stash" --include-untracked 2>&1; then
    json_error "stash_failed" "Failed to stash uncommitted changes"
  fi
  STASHED=true
fi

# Step 2: Fetch from origin
if ! git -C "$WORKTREE" fetch origin 2>&1; then
  json_error "fetch_failed" "Failed to fetch from origin"
fi

# Step 3: Sync branches using existing sync script (optional, can fail)
SYNC_SCRIPT="$PLUGIN_ROOT/skills/syncing-branches/scripts/sync-branch.sh"
if [[ -f "$SYNC_SCRIPT" ]]; then
  # Sync is best-effort - we continue even if it fails
  # The main rebase/merge will show any issues
  "$SYNC_SCRIPT" "$WORKTREE" >/dev/null 2>&1 || true
fi

# Step 4: Count commits to process
COMMIT_COUNT=$(git -C "$WORKTREE" rev-list --count "$BASE_BRANCH..HEAD" 2>/dev/null || echo "0")

# Step 5: Execute rebase or merge
if [[ "$MODE" == "rebase" ]]; then
  OPERATION_OUTPUT=$(git -C "$WORKTREE" rebase "$BASE_BRANCH" 2>&1)
  OPERATION_EXIT=$?
else
  OPERATION_OUTPUT=$(git -C "$WORKTREE" merge "$BASE_BRANCH" 2>&1)
  OPERATION_EXIT=$?
fi

# Step 6: Check for conflicts
if [[ $OPERATION_EXIT -ne 0 ]]; then
  # Check if it's a conflict situation
  if echo "$OPERATION_OUTPUT" | grep -qiE "conflict|CONFLICT|merge conflict"; then
    # Get list of conflicting files
    CONFLICT_FILES=$(git -C "$WORKTREE" diff --name-only --diff-filter=U 2>/dev/null)
    json_conflicts "$MODE" "$BASE_BRANCH" "$FEATURE_BRANCH" "$CONFLICT_FILES" "$STASHED"
    exit 1
  fi

  # Check for "already up to date"
  if echo "$OPERATION_OUTPUT" | grep -qi "already up.to.date\|Already up to date"; then
    # Pop stash if needed
    if [[ "$STASHED" == "true" ]]; then
      git -C "$WORKTREE" stash pop >/dev/null 2>&1 || true
    fi
    echo "{\"success\": true, \"mode\": \"$MODE\", \"base\": \"$BASE_BRANCH\", \"feature\": \"$FEATURE_BRANCH\", \"commits_processed\": 0, \"stashed\": $STASHED, \"conflicts\": false, \"already_up_to_date\": true}"
    exit 0
  fi

  # Other error
  json_error "${MODE}_failed" "$OPERATION_OUTPUT"
fi

# Step 7: Pop stash if we stashed
if [[ "$STASHED" == "true" ]]; then
  STASH_OUTPUT=$(git -C "$WORKTREE" stash pop 2>&1)
  if [[ $? -ne 0 ]]; then
    # Stash pop had conflicts - report as warning but operation succeeded
    echo "{\"success\": true, \"mode\": \"$MODE\", \"base\": \"$BASE_BRANCH\", \"feature\": \"$FEATURE_BRANCH\", \"commits_processed\": $COMMIT_COUNT, \"stashed\": true, \"conflicts\": false, \"stash_conflict\": true, \"stash_message\": \"Stash pop had conflicts. Resolve manually.\"}"
    exit 0
  fi
fi

# Success
json_success "$MODE" "$BASE_BRANCH" "$FEATURE_BRANCH" "$COMMIT_COUNT" "$STASHED"
