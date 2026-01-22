#!/usr/bin/env bash
# issue-update.sh - Update GitHub issue fields
#
# Usage: issue-update.sh <issue> [options]
#   issue: Issue number or URL
#
# Options:
#   --title <text>          Update title
#   --body <text>           Update body
#   --add-label <label>     Add label (repeatable)
#   --remove-label <label>  Remove label (repeatable)
#   --set-labels <labels>   Replace all labels (comma-separated)
#   --milestone <name>      Set milestone (empty string to clear)
#   --assignee <user>       Add assignee (repeatable)
#   --state <state>         open or closed
#   --execute               Apply updates (default: preview only)
#
# Exit codes:
#   0 - Success (info mode: changes ready, execute mode: updated)
#   1 - No changes detected
#   2 - Error (issue not found, invalid field, gh CLI error)
#
# Output: JSON with changes preview or update result

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

array_to_json() {
    local arr=("$@")
    local result="["
    local first=true
    for item in "${arr[@]}"; do
        if [[ -n "$item" ]]; then
            if $first; then
                first=false
            else
                result+=", "
            fi
            result+="\"$(json_escape "$item")\""
        fi
    done
    result+="]"
    echo "$result"
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
NEW_TITLE=""
NEW_BODY=""
ADD_LABELS=()
REMOVE_LABELS=()
SET_LABELS=""
NEW_MILESTONE=""
NEW_ASSIGNEES=()
NEW_STATE=""
EXECUTE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)
            NEW_TITLE="$2"
            shift 2
            ;;
        --body)
            NEW_BODY="$2"
            shift 2
            ;;
        --add-label)
            ADD_LABELS+=("$2")
            shift 2
            ;;
        --remove-label)
            REMOVE_LABELS+=("$2")
            shift 2
            ;;
        --set-labels)
            SET_LABELS="$2"
            shift 2
            ;;
        --milestone)
            NEW_MILESTONE="$2"
            shift 2
            ;;
        --assignee)
            NEW_ASSIGNEES+=("$2")
            shift 2
            ;;
        --state)
            NEW_STATE="$2"
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
    error_output "missing_issue" "No issue specified" "Usage: issue-update.sh <issue> [options]"
fi

if [[ -n "$NEW_STATE" && "$NEW_STATE" != "open" && "$NEW_STATE" != "closed" ]]; then
    error_output "invalid_state" "Invalid state '$NEW_STATE'" "Use 'open' or 'closed'"
fi

# === Fetch Current Issue Info ===
ISSUE_INFO=$(gh issue view "$ISSUE" --json number,title,body,state,labels,milestone,assignees,url 2>&1) || {
    error_output "issue_not_found" "Issue #$ISSUE not found or not accessible"
}

ISSUE_NUMBER=$(echo "$ISSUE_INFO" | jq -r '.number')
CURRENT_TITLE=$(echo "$ISSUE_INFO" | jq -r '.title')
CURRENT_BODY=$(echo "$ISSUE_INFO" | jq -r '.body // ""')
CURRENT_STATE=$(echo "$ISSUE_INFO" | jq -r '.state')
CURRENT_LABELS=$(echo "$ISSUE_INFO" | jq -r '[.labels[].name] | join(",")')
CURRENT_MILESTONE=$(echo "$ISSUE_INFO" | jq -r '.milestone.title // ""')
CURRENT_ASSIGNEES=$(echo "$ISSUE_INFO" | jq -r '[.assignees[].login] | join(",")')
ISSUE_URL=$(echo "$ISSUE_INFO" | jq -r '.url')

# === Calculate Changes ===
CHANGES=""
HAS_CHANGES=false

# Title change
if [[ -n "$NEW_TITLE" && "$NEW_TITLE" != "$CURRENT_TITLE" ]]; then
    HAS_CHANGES=true
    CHANGES+="\"title\": {\"from\": \"$(json_escape "$CURRENT_TITLE")\", \"to\": \"$(json_escape "$NEW_TITLE")\"},"
fi

# Body change
if [[ -n "$NEW_BODY" && "$NEW_BODY" != "$CURRENT_BODY" ]]; then
    HAS_CHANGES=true
    CHANGES+="\"body\": {\"changed\": true},"
fi

# State change
if [[ -n "$NEW_STATE" && "$NEW_STATE" != "$CURRENT_STATE" ]]; then
    HAS_CHANGES=true
    CHANGES+="\"state\": {\"from\": \"$CURRENT_STATE\", \"to\": \"$NEW_STATE\"},"
fi

# Milestone change
if [[ -n "$NEW_MILESTONE" || "$NEW_MILESTONE" == "" ]] && [[ "${NEW_MILESTONE:-__unset__}" != "__unset__" ]]; then
    if [[ "$NEW_MILESTONE" != "$CURRENT_MILESTONE" ]]; then
        HAS_CHANGES=true
        CHANGES+="\"milestone\": {\"from\": \"$CURRENT_MILESTONE\", \"to\": \"$NEW_MILESTONE\"},"
    fi
fi

# Label changes
ADD_LABELS_JSON=$(array_to_json "${ADD_LABELS[@]}")
REMOVE_LABELS_JSON=$(array_to_json "${REMOVE_LABELS[@]}")

if [[ ${#ADD_LABELS[@]} -gt 0 || ${#REMOVE_LABELS[@]} -gt 0 || -n "$SET_LABELS" ]]; then
    HAS_CHANGES=true
    if [[ -n "$SET_LABELS" ]]; then
        CHANGES+="\"labels\": {\"set\": \"$SET_LABELS\", \"current\": \"$CURRENT_LABELS\"},"
    else
        CHANGES+="\"labels\": {\"add\": $ADD_LABELS_JSON, \"remove\": $REMOVE_LABELS_JSON, \"current\": \"$CURRENT_LABELS\"},"
    fi
fi

# Assignee changes
if [[ ${#NEW_ASSIGNEES[@]} -gt 0 ]]; then
    HAS_CHANGES=true
    NEW_ASSIGNEES_JSON=$(array_to_json "${NEW_ASSIGNEES[@]}")
    CHANGES+="\"assignees\": {\"add\": $NEW_ASSIGNEES_JSON, \"current\": \"$CURRENT_ASSIGNEES\"},"
fi

# Remove trailing comma
CHANGES="${CHANGES%,}"

# === Check if Any Changes ===
if [[ "$HAS_CHANGES" != "true" ]]; then
    json_output "no_changes" 1 \
        "\"issue\": \"$ISSUE_NUMBER\"," \
        "\"message\": \"No changes detected\""
    exit 1
fi

# === Info Mode (default) ===
if [[ "$EXECUTE" != "true" ]]; then
    json_output "ready" 0 \
        "\"issue\": \"$ISSUE_NUMBER\"," \
        "\"url\": \"$ISSUE_URL\"," \
        "\"changes\": {$CHANGES}"
    exit 0
fi

# === Execute Mode ===

# Build gh issue edit command
CMD=(gh issue edit "$ISSUE_NUMBER")

if [[ -n "$NEW_TITLE" ]]; then
    CMD+=(--title "$NEW_TITLE")
fi

if [[ -n "$NEW_BODY" ]]; then
    CMD+=(--body "$NEW_BODY")
fi

for label in "${ADD_LABELS[@]}"; do
    if [[ -n "$label" ]]; then
        CMD+=(--add-label "$label")
    fi
done

for label in "${REMOVE_LABELS[@]}"; do
    if [[ -n "$label" ]]; then
        CMD+=(--remove-label "$label")
    fi
done

if [[ -n "$NEW_MILESTONE" ]]; then
    CMD+=(--milestone "$NEW_MILESTONE")
elif [[ "${NEW_MILESTONE:-__unset__}" == "" ]]; then
    # Clear milestone - need to use API
    gh api -X PATCH "/repos/:owner/:repo/issues/$ISSUE_NUMBER" -f milestone= > /dev/null 2>&1 || true
fi

for assignee in "${NEW_ASSIGNEES[@]}"; do
    if [[ -n "$assignee" ]]; then
        CMD+=(--add-assignee "$assignee")
    fi
done

# Execute the update
if [[ ${#CMD[@]} -gt 3 ]]; then
    OUTPUT=$("${CMD[@]}" 2>&1) || {
        error_output "update_failed" "Failed to update issue: $OUTPUT"
    }
fi

# Handle state change separately
if [[ -n "$NEW_STATE" ]]; then
    if [[ "$NEW_STATE" == "closed" ]]; then
        gh issue close "$ISSUE_NUMBER" > /dev/null 2>&1 || {
            error_output "state_change_failed" "Failed to close issue"
        }
    else
        gh issue reopen "$ISSUE_NUMBER" > /dev/null 2>&1 || {
            error_output "state_change_failed" "Failed to reopen issue"
        }
    fi
fi

json_output "success" 0 \
    "\"issue\": \"$ISSUE_NUMBER\"," \
    "\"updated\": true," \
    "\"url\": \"$ISSUE_URL\""
