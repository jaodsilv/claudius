#!/usr/bin/env bash
# issue-create.sh - Create GitHub issues with validation
#
# Usage: issue-create.sh [options]
#
# Options:
#   --title <text>      Issue title (required)
#   --body <text>       Issue body (markdown)
#   --template <name>   Template name from .github/ISSUE_TEMPLATE/
#   --label <label>     Label (repeatable)
#   --assignee <user>   Assignee (repeatable)
#   --milestone <name>  Milestone name
#   --project <name>    Project name or number
#   --priority <level>  Add priority:<level> label
#   --execute           Create the issue (default: preview only)
#
# Exit codes:
#   0 - Success (info mode: ready to create, execute mode: created)
#   2 - Error (missing title, invalid template, gh CLI error)
#
# Output: JSON with issue preview or creation result

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

# Convert array to JSON array
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
TITLE=""
BODY=""
TEMPLATE=""
LABELS=()
ASSIGNEES=()
MILESTONE=""
PROJECT=""
PRIORITY=""
EXECUTE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)
            TITLE="$2"
            shift 2
            ;;
        --body)
            BODY="$2"
            shift 2
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --label)
            LABELS+=("$2")
            shift 2
            ;;
        --assignee)
            ASSIGNEES+=("$2")
            shift 2
            ;;
        --milestone)
            MILESTONE="$2"
            shift 2
            ;;
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --priority)
            PRIORITY="$2"
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
            error_output "unexpected_arg" "Unexpected argument: $1"
            ;;
    esac
done

# === Validation ===
if [[ -z "$TITLE" ]]; then
    error_output "missing_title" "Issue title is required" "Use --title <text>"
fi

# Add priority label if specified
if [[ -n "$PRIORITY" ]]; then
    LABELS+=("priority:$PRIORITY")
fi

# === Template Handling ===
TEMPLATE_USED=""
TEMPLATE_BODY=""

if [[ -n "$TEMPLATE" ]]; then
    TEMPLATE_PATH=".github/ISSUE_TEMPLATE/$TEMPLATE"
    if [[ -f "$TEMPLATE_PATH" ]]; then
        TEMPLATE_USED="$TEMPLATE"
        # Extract body from template (skip frontmatter)
        if [[ -z "$BODY" ]]; then
            IN_FRONTMATTER=false
            while IFS= read -r line; do
                if [[ "$line" == "---" ]]; then
                    if $IN_FRONTMATTER; then
                        IN_FRONTMATTER=false
                        continue
                    else
                        IN_FRONTMATTER=true
                        continue
                    fi
                fi
                if ! $IN_FRONTMATTER; then
                    TEMPLATE_BODY+="$line"$'\n'
                fi
            done < "$TEMPLATE_PATH"
            BODY="$TEMPLATE_BODY"
        fi
    elif [[ -f "${TEMPLATE_PATH}.md" ]]; then
        TEMPLATE_USED="$TEMPLATE"
        if [[ -z "$BODY" ]]; then
            IN_FRONTMATTER=false
            while IFS= read -r line; do
                if [[ "$line" == "---" ]]; then
                    if $IN_FRONTMATTER; then
                        IN_FRONTMATTER=false
                        continue
                    else
                        IN_FRONTMATTER=true
                        continue
                    fi
                fi
                if ! $IN_FRONTMATTER; then
                    TEMPLATE_BODY+="$line"$'\n'
                fi
            done < "${TEMPLATE_PATH}.md"
            BODY="$TEMPLATE_BODY"
        fi
    else
        error_output "template_not_found" "Template '$TEMPLATE' not found" "Check .github/ISSUE_TEMPLATE/ directory"
    fi
fi

# === Validate Labels Exist ===
INVALID_LABELS=()
if [[ ${#LABELS[@]} -gt 0 ]]; then
    REPO_LABELS=$(gh label list --json name --jq '.[].name' 2>/dev/null || echo "")
    for label in "${LABELS[@]}"; do
        if [[ -n "$label" ]] && ! echo "$REPO_LABELS" | grep -qx "$label"; then
            INVALID_LABELS+=("$label")
        fi
    done
fi

# === Validate Milestone Exists ===
MILESTONE_VALID=true
if [[ -n "$MILESTONE" ]]; then
    MILESTONES=$(gh api repos/:owner/:repo/milestones --jq '.[].title' 2>/dev/null || echo "")
    if ! echo "$MILESTONES" | grep -qx "$MILESTONE"; then
        MILESTONE_VALID=false
    fi
fi

# === Info Mode (default) ===
if [[ "$EXECUTE" != "true" ]]; then
    LABELS_JSON=$(array_to_json "${LABELS[@]}")
    ASSIGNEES_JSON=$(array_to_json "${ASSIGNEES[@]}")
    INVALID_LABELS_JSON=$(array_to_json "${INVALID_LABELS[@]}")

    WARNINGS=""
    if [[ ${#INVALID_LABELS[@]} -gt 0 ]]; then
        WARNINGS+="Labels not found: ${INVALID_LABELS[*]}. "
    fi
    if [[ "$MILESTONE_VALID" == "false" ]]; then
        WARNINGS+="Milestone '$MILESTONE' not found. "
    fi

    json_output "ready" 0 \
        "\"title\": \"$(json_escape "$TITLE")\"," \
        "\"body\": \"$(json_escape "$BODY")\"," \
        "\"labels\": $LABELS_JSON," \
        "\"assignees\": $ASSIGNEES_JSON," \
        "\"milestone\": \"$MILESTONE\"," \
        "\"project\": \"$PROJECT\"," \
        "\"template_used\": \"$TEMPLATE_USED\"," \
        "\"invalid_labels\": $INVALID_LABELS_JSON," \
        "\"milestone_valid\": $MILESTONE_VALID," \
        "\"warnings\": \"$(json_escape "$WARNINGS")\""
    exit 0
fi

# === Execute Mode ===

# Build gh issue create command
CMD=(gh issue create --title "$TITLE")

if [[ -n "$BODY" ]]; then
    CMD+=(--body "$BODY")
fi

for label in "${LABELS[@]}"; do
    if [[ -n "$label" ]]; then
        CMD+=(--label "$label")
    fi
done

for assignee in "${ASSIGNEES[@]}"; do
    if [[ -n "$assignee" ]]; then
        CMD+=(--assignee "$assignee")
    fi
done

if [[ -n "$MILESTONE" ]]; then
    CMD+=(--milestone "$MILESTONE")
fi

if [[ -n "$PROJECT" ]]; then
    CMD+=(--project "$PROJECT")
fi

# Execute the command
OUTPUT=$("${CMD[@]}" 2>&1) || {
    error_output "create_failed" "Failed to create issue: $OUTPUT"
}

# Parse the URL to get issue number
ISSUE_URL="$OUTPUT"
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$' || echo "")

if [[ -z "$ISSUE_NUMBER" ]]; then
    # Try to get from the output
    ISSUE_NUMBER=$(echo "$OUTPUT" | grep -oE '#[0-9]+' | tr -d '#' || echo "unknown")
fi

json_output "success" 0 \
    "\"number\": \"$ISSUE_NUMBER\"," \
    "\"url\": \"$(json_escape "$ISSUE_URL")\"," \
    "\"title\": \"$(json_escape "$TITLE")\"," \
    "\"state\": \"open\""
