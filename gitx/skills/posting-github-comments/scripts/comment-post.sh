#!/usr/bin/env bash
# comment-post.sh - Post comments to GitHub PRs or issues
#
# Usage: comment-post.sh <type> [number] [options]
#   type: pr | issue
#   number: PR or issue number (optional, inferred from branch if omitted)
#
# Options:
#   --body <text>       Comment body text
#   --infer             Only infer and output target info (don't post)
#   --get-commits       Output commit info for summary generation
#   --since <sha>       Get commits since this SHA (for summaries)
#
# Exit codes:
#   0 - Success
#   1 - Needs input (no body provided)
#   2 - Error (target not found, etc.)
#
# Output: JSON with target info or operation result

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
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Infer PR number from current branch
infer_pr_number() {
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    if [[ -z "$branch" ]]; then
        return 1
    fi

    # Try to get PR for this branch
    local pr_number
    pr_number=$(gh pr view "$branch" --json number --jq '.number' 2>/dev/null || echo "")

    if [[ -n "$pr_number" ]]; then
        echo "$pr_number"
        return 0
    fi

    return 1
}

# Infer issue number from branch name
infer_issue_from_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    # Pattern: issue-123/... or issue-123-...
    if [[ "$branch" =~ issue-([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    # Pattern: 123-description or fix/123-description
    if [[ "$branch" =~ /([0-9]+)- ]] || [[ "$branch" =~ ^([0-9]+)- ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

# Get commit info for summary
get_commit_info() {
    local since_sha="$1"
    local commits_json="["
    local first=true

    local log_cmd="git log --oneline"
    if [[ -n "$since_sha" ]]; then
        log_cmd="$log_cmd ${since_sha}..HEAD"
    else
        log_cmd="$log_cmd -10"
    fi

    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            if $first; then
                first=false
            else
                commits_json+=", "
            fi
            local sha="${line%% *}"
            local msg="${line#* }"
            commits_json+="{\"sha\": \"$sha\", \"message\": \"$(json_escape "$msg")\"}"
        fi
    done < <($log_cmd 2>/dev/null || true)

    commits_json+="]"
    echo "$commits_json"
}

# === Argument Parsing ===
TYPE=""
NUMBER=""
BODY=""
INFER_ONLY=false
GET_COMMITS=false
SINCE_SHA=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        pr|issue)
            TYPE="$1"
            shift
            ;;
        --body)
            BODY="$2"
            shift 2
            ;;
        --infer)
            INFER_ONLY=true
            shift
            ;;
        --get-commits)
            GET_COMMITS=true
            shift
            ;;
        --since)
            SINCE_SHA="$2"
            shift 2
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            if [[ -z "$TYPE" ]]; then
                TYPE="$1"
            elif [[ -z "$NUMBER" && "$1" =~ ^[0-9]+$ ]]; then
                NUMBER="$1"
            else
                error_output "unexpected_arg" "Unexpected argument: $1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$TYPE" ]]; then
    error_output "missing_type" "No type specified. Usage: comment-post.sh <pr|issue> [number] [options]"
fi

if [[ "$TYPE" != "pr" && "$TYPE" != "issue" ]]; then
    error_output "invalid_type" "Invalid type '$TYPE'. Must be 'pr' or 'issue'."
fi

# === Infer Number if Not Provided ===
if [[ -z "$NUMBER" ]]; then
    if [[ "$TYPE" == "pr" ]]; then
        NUMBER=$(infer_pr_number || echo "")
    else
        NUMBER=$(infer_issue_from_branch || echo "")
    fi
fi

# === Get Commits Mode ===
if [[ "$GET_COMMITS" == "true" ]]; then
    COMMITS_JSON=$(get_commit_info "$SINCE_SHA")

    # Get diff stats
    DIFF_STAT=""
    if [[ -n "$SINCE_SHA" ]]; then
        DIFF_STAT=$(git diff --stat "${SINCE_SHA}..HEAD" 2>/dev/null | tail -1 || echo "")
    else
        DIFF_STAT=$(git diff --stat HEAD~10..HEAD 2>/dev/null | tail -1 || echo "")
    fi

    json_output "commits" 0 \
        "\"commits\": $COMMITS_JSON," \
        "\"since_sha\": \"$SINCE_SHA\"," \
        "\"diff_summary\": \"$(json_escape "$DIFF_STAT")\""
    exit 0
fi

# === Validate Target Exists ===
if [[ -z "$NUMBER" ]]; then
    if [[ "$INFER_ONLY" == "true" ]]; then
        json_output "not_found" 1 \
            "\"type\": \"$TYPE\"," \
            "\"message\": \"Could not infer $TYPE number from current branch\""
        exit 1
    fi
    error_output "no_number" "No $TYPE number provided and could not infer from branch."
fi

# Validate target exists
TARGET_INFO=""
if [[ "$TYPE" == "pr" ]]; then
    TARGET_INFO=$(gh pr view "$NUMBER" --json number,title,state,url 2>/dev/null || echo "")
else
    TARGET_INFO=$(gh issue view "$NUMBER" --json number,title,state,url 2>/dev/null || echo "")
fi

if [[ -z "$TARGET_INFO" ]]; then
    error_output "target_not_found" "$TYPE #$NUMBER not found or gh CLI not authenticated."
fi

# Parse target info
TARGET_TITLE=$(echo "$TARGET_INFO" | grep -o '"title":"[^"]*"' | head -1 | sed 's/"title":"//' | sed 's/"$//')
TARGET_STATE=$(echo "$TARGET_INFO" | grep -o '"state":"[^"]*"' | head -1 | sed 's/"state":"//' | sed 's/"$//')
TARGET_URL=$(echo "$TARGET_INFO" | grep -o '"url":"[^"]*"' | head -1 | sed 's/"url":"//' | sed 's/"$//')

# === Infer Mode ===
if [[ "$INFER_ONLY" == "true" ]]; then
    json_output "found" 0 \
        "\"type\": \"$TYPE\"," \
        "\"number\": $NUMBER," \
        "\"title\": \"$(json_escape "$TARGET_TITLE")\"," \
        "\"state\": \"$TARGET_STATE\"," \
        "\"url\": \"$TARGET_URL\""
    exit 0
fi

# === Post Comment ===
if [[ -z "$BODY" ]]; then
    json_output "needs_body" 1 \
        "\"type\": \"$TYPE\"," \
        "\"number\": $NUMBER," \
        "\"title\": \"$(json_escape "$TARGET_TITLE")\"," \
        "\"message\": \"No comment body provided. Use --body <text>.\""
    exit 1
fi

# Post the comment
COMMENT_URL=""
if [[ "$TYPE" == "pr" ]]; then
    COMMENT_URL=$(gh pr comment "$NUMBER" --body "$BODY" 2>&1 | grep -o 'https://[^ ]*' | head -1 || echo "")
else
    COMMENT_URL=$(gh issue comment "$NUMBER" --body "$BODY" 2>&1 | grep -o 'https://[^ ]*' | head -1 || echo "")
fi

if [[ -z "$COMMENT_URL" ]]; then
    # Comment posted but no URL captured - that's OK
    COMMENT_URL="$TARGET_URL"
fi

json_output "success" 0 \
    "\"type\": \"$TYPE\"," \
    "\"number\": $NUMBER," \
    "\"title\": \"$(json_escape "$TARGET_TITLE")\"," \
    "\"comment_url\": \"$COMMENT_URL\"," \
    "\"body_length\": ${#BODY}"
