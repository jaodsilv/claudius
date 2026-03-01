#!/usr/bin/env bash
# issue-list.sh - List and filter GitHub issues
#
# Usage: issue-list.sh [options]
#
# Options:
#   --state <state>       open (default), closed, or all
#   --label <label>       Filter by label (repeatable)
#   --assignee <user>     Filter by assignee (@me for current user)
#   --milestone <name>    Filter by milestone
#   --priority <level>    Filter by priority:<level> label
#   --limit <n>           Maximum results (default: 30, max: 100)
#   --format <format>     json (default) or table
#   --sort <field>        created, updated, comments (default: created)
#   --direction <dir>     asc or desc (default: desc)
#
# Exit codes:
#   0 - Success (may return empty array if no matches)
#   2 - Error (invalid filter, gh CLI error)
#
# Output: JSON array or formatted table

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

# === Check Prerequisites ===
if ! command -v gh &> /dev/null; then
    error_output "gh_not_found" "gh CLI not found" "Install GitHub CLI: https://cli.github.com/"
fi

if ! gh auth status &> /dev/null; then
    error_output "gh_not_authenticated" "gh CLI not authenticated" "Run: gh auth login"
fi

# === Argument Parsing ===
STATE="open"
LABELS=()
ASSIGNEE=""
MILESTONE=""
PRIORITY=""
LIMIT=30
FORMAT="json"
SORT="created"
DIRECTION="desc"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --state)
            STATE="$2"
            shift 2
            ;;
        --label)
            LABELS+=("$2")
            shift 2
            ;;
        --assignee)
            ASSIGNEE="$2"
            shift 2
            ;;
        --milestone)
            MILESTONE="$2"
            shift 2
            ;;
        --priority)
            PRIORITY="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --sort)
            SORT="$2"
            shift 2
            ;;
        --direction)
            DIRECTION="$2"
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

# === Validation ===
if [[ "$STATE" != "open" && "$STATE" != "closed" && "$STATE" != "all" ]]; then
    error_output "invalid_state" "Invalid state '$STATE'" "Use 'open', 'closed', or 'all'"
fi

if [[ "$FORMAT" != "json" && "$FORMAT" != "table" ]]; then
    error_output "invalid_format" "Invalid format '$FORMAT'" "Use 'json' or 'table'"
fi

if [[ "$SORT" != "created" && "$SORT" != "updated" && "$SORT" != "comments" ]]; then
    error_output "invalid_sort" "Invalid sort field '$SORT'" "Use 'created', 'updated', or 'comments'"
fi

if [[ "$DIRECTION" != "asc" && "$DIRECTION" != "desc" ]]; then
    error_output "invalid_direction" "Invalid direction '$DIRECTION'" "Use 'asc' or 'desc'"
fi

if [[ "$LIMIT" -gt 100 ]]; then
    LIMIT=100
fi

# Add priority to labels if specified
if [[ -n "$PRIORITY" ]]; then
    LABELS+=("priority:$PRIORITY")
fi

# === Build Command ===
CMD=(gh issue list --state "$STATE" --limit "$LIMIT" --json number,title,state,labels,assignees,milestone,createdAt,updatedAt,url,comments)

for label in "${LABELS[@]}"; do
    if [[ -n "$label" ]]; then
        CMD+=(--label "$label")
    fi
done

if [[ -n "$ASSIGNEE" ]]; then
    CMD+=(--assignee "$ASSIGNEE")
fi

if [[ -n "$MILESTONE" ]]; then
    CMD+=(--milestone "$MILESTONE")
fi

# === Execute Query ===
ISSUES_RAW=$("${CMD[@]}" 2>&1) || {
    error_output "list_failed" "Failed to list issues: $ISSUES_RAW"
}

# === Process and Sort Results ===
# Use jq for sorting and formatting
case "$SORT" in
    created)
        SORT_FIELD=".createdAt"
        ;;
    updated)
        SORT_FIELD=".updatedAt"
        ;;
    comments)
        SORT_FIELD=".comments | length"
        ;;
esac

if [[ "$DIRECTION" == "desc" ]]; then
    SORT_DIR="reverse"
else
    SORT_DIR="."
fi

# Transform to simpler format
JQ_TRANSFORM='[.[] | {
    number: .number,
    title: .title,
    state: .state,
    labels: [.labels[].name],
    assignees: [.assignees[].login],
    milestone: (.milestone.title // null),
    created_at: .createdAt,
    updated_at: .updatedAt,
    comments: (.comments | length),
    url: .url
}]'

ISSUES_JSON=$(echo "$ISSUES_RAW" | jq "$JQ_TRANSFORM" 2>/dev/null) || {
    # If jq fails, return raw output
    ISSUES_JSON="$ISSUES_RAW"
}

# === Output ===
if [[ "$FORMAT" == "json" ]]; then
    echo "$ISSUES_JSON"
else
    # Table format
    echo "#     State   Priority  Title                                     Assignee      Milestone"
    echo "----  ------  --------  ----------------------------------------  ------------  -----------"

    echo "$ISSUES_JSON" | jq -r '.[] | [
        .number,
        .state,
        ((.labels | map(select(startswith("priority:"))) | first // "none") | sub("priority:"; "")),
        (.title | if length > 40 then .[:37] + "..." else . end),
        ((.assignees | first) // "unassigned"),
        (.milestone // "none")
    ] | @tsv' 2>/dev/null | while IFS=$'\t' read -r num state priority title assignee milestone; do
        printf "%-5s %-7s %-9s %-41s %-13s %s\n" "$num" "$state" "$priority" "$title" "$assignee" "$milestone"
    done
fi

exit 0
