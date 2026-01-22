#!/bin/bash
# Merges a PR and handles post-merge cleanup
# Usage: merge-pr.sh [pr_number] [options]
# Options:
#   --squash            Use squash merge (default)
#   --merge             Use merge commit
#   --rebase            Use rebase merge
#   --delete-branch     Delete the branch after merge
#   --delete-worktree   Delete the worktree after merge
#   --delete-remote     Delete the remote branch after merge
#   -d                  Shorthand for --delete-branch --delete-remote
#   --worktree <path>   Worktree path (default: current directory)
#
# Exit codes:
#   0: Success
#   1: Pre-flight check failed (needs user decision)
#   2: Error
#
# Output: JSON with merge results

set -uo pipefail

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Convert Windows paths to bash format
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# JSON output helpers
json_success() {
  local pr="$1" title="$2" strategy="$3" sha="$4" url="$5"
  local closed_issues="$6" branch_deleted="$7" worktree_deleted="$8" stash_conflicts="$9"
  echo "{\"success\": true, \"pr\": $pr, \"title\": \"$title\", \"strategy\": \"$strategy\", \"merge_sha\": \"$sha\", \"url\": \"$url\", \"closed_issues\": [$closed_issues], \"branch_deleted\": $branch_deleted, \"worktree_deleted\": $worktree_deleted, \"stash_conflicts\": $stash_conflicts}"
}

json_error() {
  local code="$1" message="$2"
  local escaped_msg
  escaped_msg=$(echo "$message" | sed 's/"/\\"/g' | tr '\n' ' ')
  echo "{\"success\": false, \"error\": \"$code\", \"message\": \"$escaped_msg\"}"
  exit 2
}

json_preflight_failed() {
  local check="$1" message="$2"
  echo "{\"success\": false, \"preflight_failed\": true, \"check\": \"$check\", \"message\": \"$message\"}"
  exit 1
}

# Parse arguments
PR_NUMBER=""
STRATEGY="squash"
DELETE_BRANCH=false
DELETE_WORKTREE=false
DELETE_REMOTE=false
WORKTREE="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --squash)
      STRATEGY="squash"
      shift
      ;;
    --merge)
      STRATEGY="merge"
      shift
      ;;
    --rebase)
      STRATEGY="rebase"
      shift
      ;;
    --delete-branch)
      DELETE_BRANCH=true
      shift
      ;;
    --delete-worktree)
      DELETE_WORKTREE=true
      shift
      ;;
    --delete-remote)
      DELETE_REMOTE=true
      shift
      ;;
    -d)
      DELETE_BRANCH=true
      DELETE_REMOTE=true
      shift
      ;;
    --worktree)
      WORKTREE="$2"
      shift 2
      ;;
    *)
      # Assume it's the PR number if numeric
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        PR_NUMBER="$1"
      else
        json_error "invalid_argument" "Unknown argument: $1"
      fi
      shift
      ;;
  esac
done

# Convert worktree path
WORKTREE=$(convert_path "$WORKTREE")
if [[ "$WORKTREE" == "." ]]; then
  WORKTREE=$(convert_path "$(pwd)")
elif [[ ! "$WORKTREE" = /* ]]; then
  WORKTREE=$(convert_path "$(cd "$WORKTREE" && pwd)")
fi

METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"

# Step 1: Get PR info from metadata or GitHub
if [[ -f "$METADATA_FILE" ]]; then
  # Read from metadata
  HAS_ERROR=$(yq -r '.error // false' "$METADATA_FILE" 2>/dev/null)
  NO_PR=$(yq -r '.noPr // false' "$METADATA_FILE" 2>/dev/null)

  if [[ "$HAS_ERROR" != "true" ]] && [[ "$NO_PR" != "true" ]]; then
    [[ -z "$PR_NUMBER" ]] && PR_NUMBER=$(yq -r '.pr // ""' "$METADATA_FILE" 2>/dev/null)
    BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE" 2>/dev/null)
    BASE=$(yq -r '.base // ""' "$METADATA_FILE" 2>/dev/null)
    TITLE=$(yq -r '.title // ""' "$METADATA_FILE" 2>/dev/null)
    DESCRIPTION=$(yq -r '.description // ""' "$METADATA_FILE" 2>/dev/null)
  fi
fi

# Fallback to gh cli if no PR number yet
if [[ -z "$PR_NUMBER" ]]; then
  PR_INFO=$(gh pr view --json number,headRefName,baseRefName,title,body 2>/dev/null || echo "")
  if [[ -z "$PR_INFO" ]] || [[ "$PR_INFO" == "null" ]]; then
    json_error "no_pr" "No PR found for current branch. Create one first."
  fi
  PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number')
  BRANCH=$(echo "$PR_INFO" | jq -r '.headRefName')
  BASE=$(echo "$PR_INFO" | jq -r '.baseRefName')
  TITLE=$(echo "$PR_INFO" | jq -r '.title')
  DESCRIPTION=$(echo "$PR_INFO" | jq -r '.body')
fi

# Validate PR number
if [[ -z "$PR_NUMBER" ]] || [[ "$PR_NUMBER" == "null" ]]; then
  json_error "no_pr" "Could not determine PR number"
fi

# Step 2: Pre-flight checks
PREFLIGHT_SCRIPT="$PLUGIN_ROOT/skills/performing-pr-preflight-checks/scripts/pr-preflight.sh"
if [[ -f "$PREFLIGHT_SCRIPT" ]]; then
  PREFLIGHT_OUTPUT=$("$PREFLIGHT_SCRIPT" --for-merge "$PR_NUMBER" 2>&1)
  PREFLIGHT_EXIT=$?

  if [[ $PREFLIGHT_EXIT -ne 0 ]]; then
    # Extract the failing check
    FAILED_CHECK=$(echo "$PREFLIGHT_OUTPUT" | jq -r '.checks[] | select(.status == "FAIL") | .check' 2>/dev/null | head -1)
    FAILED_MSG=$(echo "$PREFLIGHT_OUTPUT" | jq -r '.checks[] | select(.status == "FAIL") | .message' 2>/dev/null | head -1)

    if [[ -n "$FAILED_CHECK" ]]; then
      json_preflight_failed "$FAILED_CHECK" "$FAILED_MSG"
    fi
  fi
fi

# Step 3: Sync branches before merge
SYNC_SCRIPT="$PLUGIN_ROOT/skills/syncing-branches/scripts/sync-branch.sh"
if [[ -f "$SYNC_SCRIPT" ]]; then
  # Best-effort sync
  "$SYNC_SCRIPT" "$WORKTREE" >/dev/null 2>&1 || true
fi

# Step 4: Execute merge
MERGE_OUTPUT=$(gh pr merge "$PR_NUMBER" --"$STRATEGY" --auto 2>&1)
MERGE_EXIT=$?

if [[ $MERGE_EXIT -ne 0 ]]; then
  # Check for common issues
  if echo "$MERGE_OUTPUT" | grep -qi "not mergeable"; then
    json_error "not_mergeable" "PR is not mergeable. Resolve conflicts or check requirements."
  elif echo "$MERGE_OUTPUT" | grep -qi "checks.*required\|status.*checks"; then
    json_error "checks_required" "Required status checks have not passed."
  elif echo "$MERGE_OUTPUT" | grep -qi "review.*required"; then
    json_error "review_required" "Required reviews have not been provided."
  else
    json_error "merge_failed" "$MERGE_OUTPUT"
  fi
fi

# Get merge commit SHA
MERGE_SHA=$(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null | cut -c1-7)

# Step 5: Parse issue references and close them
CLOSED_ISSUES=""
if [[ -n "$DESCRIPTION" ]]; then
  # Extract issue numbers from Closes/Fixes/Resolves #123 patterns
  ISSUE_REFS=$(echo "$DESCRIPTION" | grep -oE "(Closes|Fixes|Resolves)\s*#[0-9]+" | grep -oE "#[0-9]+" | tr -d '#' | sort -u)

  for issue in $ISSUE_REFS; do
    # Check if issue is still open
    ISSUE_STATE=$(gh issue view "$issue" --json state --jq '.state' 2>/dev/null || echo "")
    if [[ "$ISSUE_STATE" == "OPEN" ]]; then
      # GitHub usually auto-closes, but verify
      sleep 1  # Brief wait for GitHub to process
      ISSUE_STATE=$(gh issue view "$issue" --json state --jq '.state' 2>/dev/null || echo "")
      if [[ "$ISSUE_STATE" == "OPEN" ]]; then
        # Manually close if not auto-closed
        gh issue close "$issue" -c "Closed via PR #$PR_NUMBER" 2>/dev/null || true
      fi
    fi

    if [[ -n "$CLOSED_ISSUES" ]]; then
      CLOSED_ISSUES="$CLOSED_ISSUES, $issue"
    else
      CLOSED_ISSUES="$issue"
    fi
  done
fi

# Step 6: Cleanup
BRANCH_DELETED=false
WORKTREE_DELETED=false

# Delete worktree if requested
if [[ "$DELETE_WORKTREE" == "true" ]]; then
  WORKTREE_COUNT=$(git worktree list | wc -l)
  if [[ "$WORKTREE_COUNT" -gt 1 ]] && [[ "$WORKTREE" != "$(git rev-parse --show-toplevel 2>/dev/null)" ]]; then
    git worktree remove "$WORKTREE" --force 2>/dev/null && WORKTREE_DELETED=true
  fi
fi

# Delete local branch if requested
if [[ "$DELETE_BRANCH" == "true" ]] && [[ -n "$BRANCH" ]]; then
  CURRENT=$(git branch --show-current 2>/dev/null)
  if [[ "$CURRENT" == "$BRANCH" ]]; then
    # Switch to base first
    git switch "$BASE" 2>/dev/null || git switch main 2>/dev/null || git switch master 2>/dev/null || true
  fi
  git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH" 2>/dev/null && BRANCH_DELETED=true
fi

# Delete remote branch if requested
if [[ "$DELETE_REMOTE" == "true" ]] && [[ -n "$BRANCH" ]]; then
  git push origin --delete "$BRANCH" 2>/dev/null || true
fi

# Step 7: Pull latest on base branch
STASH_CONFLICTS=false
if [[ -n "$BASE" ]]; then
  # Determine target directory for pull
  TARGET_DIR="$WORKTREE"
  NEED_SWITCH=true

  # Check if multi-worktree environment
  WORKTREE_COUNT=$(git worktree list 2>/dev/null | wc -l)
  if [[ "$WORKTREE_COUNT" -gt 1 ]]; then
    # Find worktree where base branch is checked out
    BASE_WORKTREE=$(git worktree list --porcelain 2>/dev/null | awk -v base="$BASE" '
      /^worktree / { wt = substr($0, 10) }
      /^branch / { branch = substr($0, 8); gsub("refs/heads/", "", branch); if (branch == base) print wt }
    ')
    if [[ -n "$BASE_WORKTREE" ]]; then
      TARGET_DIR="$BASE_WORKTREE"
      NEED_SWITCH=false
    fi
  fi

  # Check for uncommitted changes in target
  HAS_CHANGES=false
  if [[ -n "$(git -C "$TARGET_DIR" status --porcelain 2>/dev/null)" ]]; then
    HAS_CHANGES=true
  fi

  # Stash if needed
  STASH_CREATED=false
  if [[ "$HAS_CHANGES" == "true" ]]; then
    git -C "$TARGET_DIR" stash push -m "merge-pr: auto-stash before pull" 2>/dev/null && STASH_CREATED=true
  fi

  # Switch to base if needed, then pull
  if [[ "$NEED_SWITCH" == "true" ]]; then
    git -C "$TARGET_DIR" switch "$BASE" 2>/dev/null && git -C "$TARGET_DIR" pull 2>/dev/null || true
  else
    git -C "$TARGET_DIR" pull 2>/dev/null || true
  fi

  # Pop stash if we created one
  if [[ "$STASH_CREATED" == "true" ]]; then
    if ! git -C "$TARGET_DIR" stash pop 2>/dev/null; then
      STASH_CONFLICTS=true
    fi
  fi
fi

# Get PR URL
PR_URL=$(gh pr view "$PR_NUMBER" --json url --jq '.url' 2>/dev/null || echo "")

# Escape title for JSON
ESCAPED_TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')

json_success "$PR_NUMBER" "$ESCAPED_TITLE" "$STRATEGY" "$MERGE_SHA" "$PR_URL" "$CLOSED_ISSUES" "$BRANCH_DELETED" "$WORKTREE_DELETED" "$STASH_CONFLICTS"
