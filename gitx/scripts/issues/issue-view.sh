#!/usr/bin/env bash
# issue-view.sh - View GitHub issue details
#
# Usage: issue-view.sh <issue> [options]
#   issue: Issue number or URL
#
# Options:
#   --json [fields]       JSON output with comma-separated fields (default fields if omitted)
#   --jq <expression>     jq filter (requires --json, passed to gh CLI)
#   --use-case <name>     Preset field selection: branch-naming, analysis, picking, pr-linking, quick
#   --comments            Include comments (markdown mode only)
#   --events              Include timeline events (markdown mode only)
#   --max-comments <n>    Maximum comments (default: 10, markdown mode only)
#
# Exit codes:
#   0 - Success
#   1 - Issue is closed (only with --use-case branch-naming)
#   2 - Error (issue not found, gh CLI error, invalid use-case)
#
# Output: Issue details in specified format

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

format_date() {
    local iso_date="$1"
    # Convert ISO date to readable format
    echo "$iso_date" | sed 's/T/ /' | sed 's/Z$//' | cut -d' ' -f1
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
OUTPUT_MODE="markdown"  # "markdown" or "json"
JSON_FIELDS=""
JQ_FILTER=""
USE_CASE=""
INCLUDE_COMMENTS=false
INCLUDE_EVENTS=false
MAX_COMMENTS=10

# Default fields when --json has no value
DEFAULT_JSON_FIELDS="assignees,author,body,closedAt,createdAt,id,labels,milestone,number,state,stateReason,title,updatedAt"

# Use-case presets
declare -A USE_CASE_FIELDS=(
    ["branch-naming"]="closedAt,labels,number,state,stateReason,title"
    ["analysis"]="author,body,closedAt,comments,createdAt,labels,milestone,title,updatedAt"
    ["picking"]="assignees,labels,milestone,number,state,title"
    ["pr-linking"]="number,title"
    ["quick"]="number,state,title,url"
)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            OUTPUT_MODE="json"
            # Check if next arg is fields (not another flag or missing)
            if [[ $# -gt 1 && ! "$2" =~ ^-- && -n "$2" ]]; then
                JSON_FIELDS="$2"
                shift 2
            else
                JSON_FIELDS="$DEFAULT_JSON_FIELDS"
                shift
            fi
            ;;
        --jq)
            JQ_FILTER="$2"
            shift 2
            ;;
        --use-case)
            USE_CASE="$2"
            shift 2
            ;;
        --comments)
            INCLUDE_COMMENTS=true
            shift
            ;;
        --events)
            INCLUDE_EVENTS=true
            shift
            ;;
        --max-comments)
            MAX_COMMENTS="$2"
            shift 2
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            if [[ -z "$ISSUE" ]]; then
                ISSUE="$1"
            else
                error_output "too_many_args" "Too many arguments"
            fi
            shift
            ;;
    esac
done

# === Validation ===
if [[ -z "$ISSUE" ]]; then
    error_output "missing_issue" "No issue specified" "Usage: issue-view.sh <issue> [options]"
fi

# Validate use-case
if [[ -n "$USE_CASE" ]]; then
    if [[ -z "${USE_CASE_FIELDS[$USE_CASE]:-}" ]]; then
        valid_cases=$(IFS=,; echo "${!USE_CASE_FIELDS[*]}")
        error_output "invalid_use_case" "Unknown use-case: $USE_CASE" "Valid: $valid_cases"
    fi
    OUTPUT_MODE="json"
    JSON_FIELDS="${USE_CASE_FIELDS[$USE_CASE]}"
fi

# --jq requires json mode
if [[ -n "$JQ_FILTER" && "$OUTPUT_MODE" != "json" ]]; then
    error_output "jq_requires_json" "--jq requires --json or --use-case"
fi

# === Fetch and Output ===
if [[ "$OUTPUT_MODE" == "json" ]]; then
    # JSON mode: use gh CLI directly with --json and optional --jq
    GH_CMD=(gh issue view "$ISSUE" --json "$JSON_FIELDS")
    if [[ -n "$JQ_FILTER" ]]; then
        GH_CMD+=( --jq "$JQ_FILTER")
    fi

    OUTPUT=$("${GH_CMD[@]}" 2>&1) || {
        error_output "issue_not_found" "Issue #$ISSUE not found or not accessible"
    }

    # Use-case specific validation
    if [[ "$USE_CASE" == "branch-naming" ]]; then
        # Check if issue is closed (only when jq filter doesn't modify structure)
        if [[ -z "$JQ_FILTER" ]]; then
            STATE=$(echo "$OUTPUT" | jq -r '.state // "OPEN"')
            if [[ "$STATE" == "CLOSED" ]]; then
                echo "$OUTPUT"  # Still output the data
                exit 1  # Exit with 1 to signal closed issue
            fi
        fi
    fi

    echo "$OUTPUT"
else
    # Markdown mode: fetch full issue info for formatted output
    ISSUE_FIELDS="number,title,body,state,labels,assignees,milestone,author,createdAt,updatedAt,url,closedAt"

    if [[ "$INCLUDE_COMMENTS" == "true" ]]; then
        ISSUE_FIELDS+=",comments"
    fi

    ISSUE_INFO=$(gh issue view "$ISSUE" --json "$ISSUE_FIELDS" 2>&1) || {
        error_output "issue_not_found" "Issue #$ISSUE not found or not accessible"
    }

    # Parse issue fields
    ISSUE_NUMBER=$(echo "$ISSUE_INFO" | jq -r '.number')
    ISSUE_TITLE=$(echo "$ISSUE_INFO" | jq -r '.title')
    ISSUE_BODY=$(echo "$ISSUE_INFO" | jq -r '.body // ""')
    ISSUE_STATE=$(echo "$ISSUE_INFO" | jq -r '.state')
    ISSUE_AUTHOR=$(echo "$ISSUE_INFO" | jq -r '.author.login')
    CREATED_AT=$(echo "$ISSUE_INFO" | jq -r '.createdAt')
    UPDATED_AT=$(echo "$ISSUE_INFO" | jq -r '.updatedAt')
    CLOSED_AT=$(echo "$ISSUE_INFO" | jq -r '.closedAt // ""')
    ISSUE_URL=$(echo "$ISSUE_INFO" | jq -r '.url')

    LABELS=$(echo "$ISSUE_INFO" | jq -r '[.labels[].name] | join(", ")' 2>/dev/null || echo "")
    ASSIGNEES=$(echo "$ISSUE_INFO" | jq -r '[.assignees[].login] | join(", ")' 2>/dev/null || echo "")
    MILESTONE=$(echo "$ISSUE_INFO" | jq -r '.milestone.title // ""')

    # Fetch Timeline Events if Requested
    EVENTS_JSON="[]"
    if [[ "$INCLUDE_EVENTS" == "true" ]]; then
        EVENTS_JSON=$(gh api "/repos/:owner/:repo/issues/$ISSUE_NUMBER/timeline" --jq '[.[] | select(.event) | {event: .event, actor: .actor.login, created_at: .created_at, label: .label.name}]' 2>/dev/null || echo "[]")
    fi

    # Markdown output
    echo "# Issue #$ISSUE_NUMBER: $ISSUE_TITLE"
    echo ""
    echo "**State**: $ISSUE_STATE"
    echo "**Created**: $(format_date "$CREATED_AT") by $ISSUE_AUTHOR"
    echo "**Updated**: $(format_date "$UPDATED_AT")"
    if [[ -n "$CLOSED_AT" && "$CLOSED_AT" != "null" ]]; then
        echo "**Closed**: $(format_date "$CLOSED_AT")"
    fi
    echo "**Labels**: ${LABELS:-none}"
    echo "**Assignees**: ${ASSIGNEES:-unassigned}"
    echo "**Milestone**: ${MILESTONE:-none}"
    echo "**URL**: $ISSUE_URL"
    echo ""
    echo "## Description"
    echo ""
    if [[ -n "$ISSUE_BODY" ]]; then
        echo "$ISSUE_BODY"
    else
        echo "_No description provided_"
    fi

    # Comments section
    if [[ "$INCLUDE_COMMENTS" == "true" ]]; then
        COMMENT_COUNT=$(echo "$ISSUE_INFO" | jq '.comments | length' 2>/dev/null || echo "0")
        echo ""
        echo "## Comments ($COMMENT_COUNT)"
        echo ""

        if [[ "$COMMENT_COUNT" -gt 0 ]]; then
            echo "$ISSUE_INFO" | jq -r --argjson max "$MAX_COMMENTS" '.comments[:$max][] | "### \(.author.login) commented on \(.createdAt | split("T")[0])\n\n\(.body)\n"' 2>/dev/null || echo "_Failed to load comments_"
        else
            echo "_No comments_"
        fi
    fi

    # Events section
    if [[ "$INCLUDE_EVENTS" == "true" && "$EVENTS_JSON" != "[]" ]]; then
        echo ""
        echo "## Timeline"
        echo ""
        echo "$EVENTS_JSON" | jq -r '.[] | "- **\(.event)** by \(.actor // "system") on \(.created_at | split("T")[0])\(if .label then " (label: \(.label))" else "" end)"' 2>/dev/null || echo "_Failed to load timeline_"
    fi
fi

exit 0
