#!/usr/bin/env bash
# commit-push.sh - Gather commit info or execute commit/push
#
# Usage: commit-push.sh [options]
#
# Options:
#   --info              Output status info for LLM to draft message (default)
#   --message <msg>     Commit with this message
#   --all               Stage all changes before commit
#   --push              Push after commit
#   --force-with-lease  Use force-with-lease when pushing
#
# Exit codes:
#   0 - Success
#   1 - Nothing to commit
#   2 - Error
#
# Output: JSON with status info or operation results

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

# Escape string for JSON
json_escape() {
    local str="$1"
    # Escape backslashes, quotes, and newlines
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# === Argument Parsing ===
INFO_MODE=true
MESSAGE=""
STAGE_ALL=false
PUSH=false
FORCE_WITH_LEASE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --info)
            INFO_MODE=true
            shift
            ;;
        --message)
            INFO_MODE=false
            MESSAGE="$2"
            shift 2
            ;;
        --all)
            STAGE_ALL=true
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --force-with-lease)
            FORCE_WITH_LEASE=true
            shift
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            error_output "unexpected_arg" "Unexpected argument: $1"
            ;;
    esac
done

# === Check Repository ===
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    error_output "not_a_repo" "Not in a git repository."
fi

# === Info Mode ===
if [[ "$INFO_MODE" == "true" ]]; then
    # Get current branch
    BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [[ -z "$BRANCH" ]]; then
        BRANCH="(detached HEAD)"
    fi

    # Get status counts
    STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l)
    UNSTAGED_COUNT=$(git diff --name-only 2>/dev/null | wc -l)
    UNTRACKED_COUNT=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

    # Get staged files (for commit)
    STAGED_FILES=$(git diff --cached --name-status 2>/dev/null | head -20 || true)
    STAGED_JSON="["
    first=true
    while IFS=$'\t' read -r status file; do
        if [[ -n "$file" ]]; then
            if $first; then
                first=false
            else
                STAGED_JSON+=", "
            fi
            STAGED_JSON+="{\"status\": \"$status\", \"file\": \"$(json_escape "$file")\"}"
        fi
    done <<< "$STAGED_FILES"
    STAGED_JSON+="]"

    # Get unstaged files
    UNSTAGED_FILES=$(git diff --name-status 2>/dev/null | head -10 || true)
    UNSTAGED_JSON="["
    first=true
    while IFS=$'\t' read -r status file; do
        if [[ -n "$file" ]]; then
            if $first; then
                first=false
            else
                UNSTAGED_JSON+=", "
            fi
            UNSTAGED_JSON+="{\"status\": \"$status\", \"file\": \"$(json_escape "$file")\"}"
        fi
    done <<< "$UNSTAGED_FILES"
    UNSTAGED_JSON+="]"

    # Get untracked files
    UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null | head -10 || true)
    UNTRACKED_JSON="["
    first=true
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            if $first; then
                first=false
            else
                UNTRACKED_JSON+=", "
            fi
            UNTRACKED_JSON+="\"$(json_escape "$file")\""
        fi
    done <<< "$UNTRACKED_FILES"
    UNTRACKED_JSON+="]"

    # Get diff summary (for understanding changes)
    DIFF_STAT=$(git diff --cached --stat 2>/dev/null | tail -1 || echo "")
    DIFF_STAT_ESCAPED=$(json_escape "$DIFF_STAT")

    # Get recent commits for style reference
    RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || true)
    COMMITS_JSON="["
    first=true
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            if $first; then
                first=false
            else
                COMMITS_JSON+=", "
            fi
            COMMITS_JSON+="\"$(json_escape "$line")\""
        fi
    done <<< "$RECENT_COMMITS"
    COMMITS_JSON+="]"

    # Check remote tracking
    UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")
    AHEAD=0
    BEHIND=0
    if [[ -n "$UPSTREAM" ]]; then
        AHEAD=$(git rev-list --count "$UPSTREAM..HEAD" 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count "HEAD..$UPSTREAM" 2>/dev/null || echo "0")
    fi

    # Check if there's anything to commit
    HAS_CHANGES=false
    if [[ "$STAGED_COUNT" -gt 0 || "$UNSTAGED_COUNT" -gt 0 || "$UNTRACKED_COUNT" -gt 0 ]]; then
        HAS_CHANGES=true
    fi

    if [[ "$HAS_CHANGES" == "false" ]]; then
        json_output "nothing_to_commit" 1 \
            "\"branch\": \"$BRANCH\"," \
            "\"message\": \"Nothing to commit, working tree clean\""
        exit 1
    fi

    json_output "ready" 0 \
        "\"branch\": \"$BRANCH\"," \
        "\"staged_count\": $STAGED_COUNT," \
        "\"unstaged_count\": $UNSTAGED_COUNT," \
        "\"untracked_count\": $UNTRACKED_COUNT," \
        "\"staged_files\": $STAGED_JSON," \
        "\"unstaged_files\": $UNSTAGED_JSON," \
        "\"untracked_files\": $UNTRACKED_JSON," \
        "\"diff_summary\": \"$DIFF_STAT_ESCAPED\"," \
        "\"recent_commits\": $COMMITS_JSON," \
        "\"upstream\": \"$UPSTREAM\"," \
        "\"ahead\": $AHEAD," \
        "\"behind\": $BEHIND"
    exit 0
fi

# === Execute Mode ===

if [[ -z "$MESSAGE" ]]; then
    error_output "no_message" "No commit message provided. Use --message <msg>."
fi

# Track what we did
STAGED_FILES_COUNT=0
COMMITTED=false
PUSHED=false
COMMIT_SHA=""

# Step 1: Stage all if requested
if [[ "$STAGE_ALL" == "true" ]]; then
    git add -A 2>&1
fi

# Step 2: Check if there's anything staged
STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l)
if [[ "$STAGED_COUNT" -eq 0 ]]; then
    error_output "nothing_staged" "Nothing staged to commit. Use --all to stage all changes."
fi
STAGED_FILES_COUNT=$STAGED_COUNT

# Step 3: Commit
# Use heredoc for message to handle special characters
if ! git commit -m "$MESSAGE" 2>&1; then
    error_output "commit_failed" "Failed to create commit"
fi
COMMITTED=true
COMMIT_SHA=$(git rev-parse --short HEAD)

# Step 4: Push if requested
if [[ "$PUSH" == "true" ]]; then
    PUSH_FLAGS=""
    if [[ "$FORCE_WITH_LEASE" == "true" ]]; then
        PUSH_FLAGS="--force-with-lease"
    fi

    # Check if upstream exists
    UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")
    if [[ -z "$UPSTREAM" ]]; then
        # No upstream, push with -u
        BRANCH=$(git branch --show-current)
        if ! git push -u origin "$BRANCH" $PUSH_FLAGS 2>&1; then
            error_output "push_failed" "Commit succeeded but push failed. Manual push required."
        fi
    else
        if ! git push $PUSH_FLAGS 2>&1; then
            error_output "push_failed" "Commit succeeded but push failed. Manual push required."
        fi
    fi
    PUSHED=true
fi

# Get branch info for output
BRANCH=$(git branch --show-current)

json_output "success" 0 \
    "\"branch\": \"$BRANCH\"," \
    "\"commit_sha\": \"$COMMIT_SHA\"," \
    "\"message\": \"$(json_escape "$MESSAGE")\"," \
    "\"files_committed\": $STAGED_FILES_COUNT," \
    "\"pushed\": $PUSHED"
