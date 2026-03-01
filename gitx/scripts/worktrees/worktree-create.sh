#!/usr/bin/env bash
# worktree-create.sh - Create a git worktree
#
# Usage: worktree-create.sh --branch <name> --dir <path> [--base <branch>]
#
# Options:
#   --branch <name>     Branch name (required) - created if doesn't exist
#   --dir <path>        Directory path (required)
#   --base <branch>     Base branch for new branches (only used if branch doesn't exist)
#
# Exit codes:
#   0 - Success
#   2 - Error
#
# Output: JSON with creation result

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

# Check if branch exists
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

# Check if directory exists
dir_exists() {
    local dir="$1"
    [[ -e "$dir" ]]
}

# === Argument Parsing ===
BRANCH=""
DIR=""
BASE_BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --dir)
            DIR="$2"
            shift 2
            ;;
        --base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            error_output "unexpected_arg" "Unexpected argument: $1"
            ;;
    esac
done

# Validate required arguments
if [[ -z "$BRANCH" ]]; then
    error_output "missing_branch" "Branch name is required. Use --branch <name>"
fi

if [[ -z "$DIR" ]]; then
    error_output "missing_dir" "Directory path is required. Use --dir <path>"
fi

# Validate directory doesn't exist
if dir_exists "$DIR"; then
    error_output "dir_exists" "Directory '$DIR' already exists."
fi

# === Create Worktree ===
BRANCH_CREATED="true"
if branch_exists "$BRANCH"; then
    # Branch exists - use existing branch
    BRANCH_CREATED="false"
    if ! git worktree add "$DIR" "$BRANCH" 2>&1; then
        error_output "worktree_failed" "Failed to create worktree"
    fi
else
    # Branch doesn't exist - create new branch
    if [[ -n "$BASE_BRANCH" ]]; then
        if ! git worktree add -b "$BRANCH" "$DIR" "$BASE_BRANCH" 2>&1; then
            error_output "worktree_failed" "Failed to create worktree"
        fi
    else
        if ! git worktree add -b "$BRANCH" "$DIR" 2>&1; then
            error_output "worktree_failed" "Failed to create worktree"
        fi
    fi
fi

# Output success
json_output "success" 0 \
    "\"branch\": \"$BRANCH\"," \
    "\"directory\": \"$DIR\"," \
    "\"base_branch\": \"$BASE_BRANCH\"," \
    "\"branch_created\": $BRANCH_CREATED"
