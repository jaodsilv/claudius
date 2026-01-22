#!/usr/bin/env bash
# remove-branch.sh - Remove a git branch locally and/or remotely
#
# Usage: remove-branch.sh <branch> [options]
#   branch: Name of the branch to remove
#
# Options:
#   -f, --force         Force delete (even if unmerged)
#   -r, --remove-remote Delete remote branch
#   --remote-only       Only delete remote branch
#   --execute           Actually perform the deletion (default: info only)
#
# Exit codes:
#   0 - Success (or info output)
#   1 - Branch is unmerged (needs user decision)
#   2 - Error (branch not found, in worktree, etc.)
#
# Output: JSON with branch info and operation results

set -euo pipefail

# === Helper Functions ===
json_output() {
    local status="$1"
    local exit_code="$2"
    shift 2

    echo "{"
    echo "  \"status\": \"$status\","
    echo "  \"exit_code\": $exit_code,"
    echo "  $*"
    echo "}"
}

error_output() {
    local code="$1"
    local message="$2"
    json_output "error" 2 "\"error_code\": \"$code\", \"message\": \"$message\""
    exit 2
}

# === Argument Parsing ===
BRANCH=""
FORCE=false
REMOVE_REMOTE=false
REMOTE_ONLY=false
EXECUTE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        -r|--remove-remote)
            REMOVE_REMOTE=true
            shift
            ;;
        --remote-only)
            REMOTE_ONLY=true
            REMOVE_REMOTE=true
            shift
            ;;
        --execute)
            EXECUTE=true
            shift
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            if [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                error_output "too_many_args" "Too many arguments. Expected one branch name."
            fi
            shift
            ;;
    esac
done

if [[ -z "$BRANCH" ]]; then
    error_output "missing_branch" "No branch specified. Usage: remove-branch.sh <branch> [options]"
fi

# === Check Branch Existence ===
LOCAL_EXISTS=false
REMOTE_EXISTS=false

if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    LOCAL_EXISTS=true
fi

if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    REMOTE_EXISTS=true
fi

if [[ "$LOCAL_EXISTS" == "false" && "$REMOTE_EXISTS" == "false" ]]; then
    error_output "branch_not_found" "Branch '$BRANCH' not found locally or on remote."
fi

if [[ "$REMOTE_ONLY" == "true" && "$REMOTE_EXISTS" == "false" ]]; then
    error_output "remote_not_found" "Remote branch 'origin/$BRANCH' not found."
fi

# === Check if Branch is Current ===
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || true)
IS_CURRENT=false
if [[ "$CURRENT_BRANCH" == "$BRANCH" ]]; then
    IS_CURRENT=true
fi

# === Check if Branch is in a Worktree ===
IN_WORKTREE=false
WORKTREE_PATH=""

WORKTREE_INFO=$(git worktree list --porcelain 2>/dev/null || true)
while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
        current_worktree="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
        if [[ "${BASH_REMATCH[1]}" == "$BRANCH" ]]; then
            IN_WORKTREE=true
            WORKTREE_PATH="$current_worktree"
        fi
    fi
done <<< "$WORKTREE_INFO"

if [[ "$IN_WORKTREE" == "true" && "$REMOTE_ONLY" != "true" ]]; then
    error_output "in_worktree" "Branch '$BRANCH' is checked out in worktree '$WORKTREE_PATH'. Remove the worktree first."
fi

# === Check Merge Status ===
IS_MERGED=false
MERGE_BASE=""

# Get default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

if [[ "$LOCAL_EXISTS" == "true" ]]; then
    # Check if branch is merged into default branch
    MERGE_BASE=$(git merge-base "$DEFAULT_BRANCH" "$BRANCH" 2>/dev/null || true)
    BRANCH_TIP=$(git rev-parse "$BRANCH" 2>/dev/null || true)

    if [[ -n "$MERGE_BASE" && "$MERGE_BASE" == "$BRANCH_TIP" ]]; then
        IS_MERGED=true
    elif git branch --merged "$DEFAULT_BRANCH" 2>/dev/null | grep -q "^\s*$BRANCH$"; then
        IS_MERGED=true
    fi
fi

# === Get Branch Info ===
LAST_COMMIT=""
LAST_COMMIT_DATE=""
AHEAD_BEHIND=""

if [[ "$LOCAL_EXISTS" == "true" ]]; then
    LAST_COMMIT=$(git log -1 --format="%h %s" "$BRANCH" 2>/dev/null | head -c 80 || true)
    LAST_COMMIT_DATE=$(git log -1 --format="%ci" "$BRANCH" 2>/dev/null || true)

    if [[ "$REMOTE_EXISTS" == "true" ]]; then
        AHEAD=$(git rev-list --count "origin/$BRANCH..$BRANCH" 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count "$BRANCH..origin/$BRANCH" 2>/dev/null || echo "0")
        AHEAD_BEHIND="ahead $AHEAD, behind $BEHIND"
    fi
fi

# === Info Mode (default) ===
if [[ "$EXECUTE" != "true" ]]; then
    if [[ "$IS_MERGED" == "false" && "$FORCE" != "true" && "$REMOTE_ONLY" != "true" ]]; then
        # Exit 1 - needs user decision about unmerged branch
        json_output "needs_confirmation" 1 \
            "\"branch\": \"$BRANCH\"," \
            "\"local_exists\": $LOCAL_EXISTS," \
            "\"remote_exists\": $REMOTE_EXISTS," \
            "\"is_current\": $IS_CURRENT," \
            "\"is_merged\": $IS_MERGED," \
            "\"default_branch\": \"$DEFAULT_BRANCH\"," \
            "\"last_commit\": \"$LAST_COMMIT\"," \
            "\"last_commit_date\": \"$LAST_COMMIT_DATE\"," \
            "\"ahead_behind\": \"$AHEAD_BEHIND\"," \
            "\"remove_remote\": $REMOVE_REMOTE," \
            "\"remote_only\": $REMOTE_ONLY"
        exit 1
    else
        json_output "ready" 0 \
            "\"branch\": \"$BRANCH\"," \
            "\"local_exists\": $LOCAL_EXISTS," \
            "\"remote_exists\": $REMOTE_EXISTS," \
            "\"is_current\": $IS_CURRENT," \
            "\"is_merged\": $IS_MERGED," \
            "\"default_branch\": \"$DEFAULT_BRANCH\"," \
            "\"last_commit\": \"$LAST_COMMIT\"," \
            "\"last_commit_date\": \"$LAST_COMMIT_DATE\"," \
            "\"ahead_behind\": \"$AHEAD_BEHIND\"," \
            "\"remove_remote\": $REMOVE_REMOTE," \
            "\"remote_only\": $REMOTE_ONLY"
        exit 0
    fi
fi

# === Execute Mode ===

# Track what we did
SWITCHED_FROM=""
REMOVED_LOCAL=false
REMOVED_REMOTE=false

# Step 1: Switch away if current branch
if [[ "$IS_CURRENT" == "true" && "$REMOTE_ONLY" != "true" ]]; then
    SWITCHED_FROM="$BRANCH"
    git checkout "$DEFAULT_BRANCH" 2>&1
fi

# Step 2: Delete local branch
if [[ "$LOCAL_EXISTS" == "true" && "$REMOTE_ONLY" != "true" ]]; then
    if [[ "$FORCE" == "true" ]]; then
        if ! git branch -D "$BRANCH" 2>&1; then
            error_output "local_delete_failed" "Failed to delete local branch '$BRANCH'"
        fi
    else
        if ! git branch -d "$BRANCH" 2>&1; then
            error_output "local_delete_failed" "Failed to delete local branch '$BRANCH'. It may not be fully merged. Use --force to delete anyway."
        fi
    fi
    REMOVED_LOCAL=true
fi

# Step 3: Delete remote branch
if [[ "$REMOVE_REMOTE" == "true" && "$REMOTE_EXISTS" == "true" ]]; then
    if ! git push origin --delete "$BRANCH" 2>&1; then
        error_output "remote_delete_failed" "Failed to delete remote branch 'origin/$BRANCH'"
    fi
    REMOVED_REMOTE=true
fi

# Output success
json_output "success" 0 \
    "\"branch\": \"$BRANCH\"," \
    "\"switched_from\": \"$SWITCHED_FROM\"," \
    "\"removed_local\": $REMOVED_LOCAL," \
    "\"removed_remote\": $REMOVED_REMOTE"
