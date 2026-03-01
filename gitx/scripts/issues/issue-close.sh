#!/usr/bin/env bash
# issue-close.sh - Close GitHub issues with optional PR linking
#
# Usage: issue-close.sh <issue> [options]
#   issue: Issue number or URL
#
# Options:
#   --reason <type>     completed (default) or not_planned
#   --comment <text>    Add comment before closing
#   --link-pr <number>  Link PR that resolves this issue
#   --execute           Close the issue (default: preview only)
#
# Exit codes:
#   0 - Success (info mode: ready to close, execute mode: closed)
#   1 - Issue already closed (no action needed)
#   2 - Error (issue not found, invalid reason, gh CLI error)
#
# Output: JSON with issue state and operation result

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
    local suggestion="${3:-}"
    if [[ -n "$suggestion" ]]; then
        json_output "error" 2 "\"error_code\": \"$code\", \"message\": \"$message\", \"suggestion\": \"$suggestion\""
    else
        json_output "error" 2 "\"error_code\": \"$code\", \"message\": \"$message\""
    fi
    exit 2
}

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# === Check Prerequisites ===
if ! command -v gh &> /dev/null; then
    error_output "gh_not_found" "gh CLI not found" "Install GitHub CLI: https://cli.github.com/"
fi

if ! gh auth status &> /dev/null; then
    error_output "gh_not_authenticated" "gh CLI not authenticated" "Run: gh auth login"
fi

# === Argument Parsing ===
ISSUE=""
REASON="completed"
COMMENT=""
LINK_PR=""
EXECUTE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reason)
            REASON="$2"
            shift 2
            ;;
        --comment)
            COMMENT="$2"
            shift 2
            ;;
        --link-pr)
            LINK_PR="$2"
            shift 2
            ;;
        --execute)
            EXECUTE=true
            shift
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            if [[ -z "$ISSUE" ]]; then
                ISSUE="$1"
            else
                error_output "too_many_args" "Too many arguments. Expected one issue number."
            fi
            shift
            ;;
    esac
done

# === Validation ===
if [[ -z "$ISSUE" ]]; then
    error_output "missing_issue" "No issue specified" "Usage: issue-close.sh <issue> [options]"
fi

# Validate reason
if [[ "$REASON" != "completed" && "$REASON" != "not_planned" ]]; then
    error_output "invalid_reason" "Invalid reason '$REASON'" "Use 'completed' or 'not_planned'"
fi

# === Fetch Issue Info ===
ISSUE_INFO=$(gh issue view "$ISSUE" --json number,title,state,url,closedAt,author 2>&1) || {
    error_output "issue_not_found" "Issue #$ISSUE not found or not accessible"
}

ISSUE_NUMBER=$(echo "$ISSUE_INFO" | grep -o '"number":[0-9]*' | grep -o '[0-9]*')
ISSUE_TITLE=$(echo "$ISSUE_INFO" | grep -o '"title":"[^"]*"' | sed 's/"title":"//' | sed 's/"$//')
ISSUE_STATE=$(echo "$ISSUE_INFO" | grep -o '"state":"[^"]*"' | sed 's/"state":"//' | sed 's/"$//')
ISSUE_URL=$(echo "$ISSUE_INFO" | grep -o '"url":"[^"]*"' | sed 's/"url":"//' | sed 's/"$//')
CLOSED_AT=$(echo "$ISSUE_INFO" | grep -o '"closedAt":"[^"]*"' | sed 's/"closedAt":"//' | sed 's/"$//' || echo "")

# === Check if Already Closed ===
if [[ "$ISSUE_STATE" == "CLOSED" ]]; then
    json_output "already_closed" 1 \
        "\"issue\": \"$ISSUE_NUMBER\"," \
        "\"title\": \"$(json_escape "$ISSUE_TITLE")\"," \
        "\"current_state\": \"closed\"," \
        "\"closed_at\": \"$CLOSED_AT\"," \
        "\"message\": \"Issue is already closed\""
    exit 1
fi

# === Build Comment if Linking PR ===
FULL_COMMENT="$COMMENT"
if [[ -n "$LINK_PR" ]]; then
    if [[ -n "$FULL_COMMENT" ]]; then
        FULL_COMMENT+=$'\n\n'
    fi
    FULL_COMMENT+="Closed via PR #$LINK_PR"
fi

# === Info Mode (default) ===
if [[ "$EXECUTE" != "true" ]]; then
    json_output "ready" 0 \
        "\"issue\": \"$ISSUE_NUMBER\"," \
        "\"title\": \"$(json_escape "$ISSUE_TITLE")\"," \
        "\"current_state\": \"open\"," \
        "\"reason\": \"$REASON\"," \
        "\"comment\": \"$(json_escape "$FULL_COMMENT")\"," \
        "\"linked_pr\": \"$LINK_PR\"," \
        "\"url\": \"$ISSUE_URL\""
    exit 0
fi

# === Execute Mode ===

# Post comment if provided
if [[ -n "$FULL_COMMENT" ]]; then
    gh issue comment "$ISSUE_NUMBER" --body "$FULL_COMMENT" > /dev/null 2>&1 || {
        error_output "comment_failed" "Failed to post comment to issue #$ISSUE_NUMBER"
    }
fi

# Close the issue
CLOSE_OUTPUT=$(gh issue close "$ISSUE_NUMBER" --reason "$REASON" 2>&1) || {
    error_output "close_failed" "Failed to close issue: $CLOSE_OUTPUT"
}

json_output "success" 0 \
    "\"issue\": \"$ISSUE_NUMBER\"," \
    "\"title\": \"$(json_escape "$ISSUE_TITLE")\"," \
    "\"state\": \"closed\"," \
    "\"reason\": \"$REASON\"," \
    "\"url\": \"$ISSUE_URL\""
