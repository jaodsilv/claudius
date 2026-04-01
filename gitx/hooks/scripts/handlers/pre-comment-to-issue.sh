#!/bin/bash
# Handler for /gitx:comment-to-issue and /gitx:fix-issue commands
# Validate issue exists, with enhanced parsing via parse-references.sh

log_section "Validate-Issue Handler"
log_debug "ARGS" "$ARGS"

# Validate mutually exclusive comment source flags (for comment-to-issue)
validate_mutually_exclusive "$ARGS" "-l or --last" "-sc or --since-commit" "-c or --single-commit"

# Validate -sc requires hash value
validate_flag_value "$ARGS" "-sc or --since-commit" "commit hash"

# Validate -c requires hash value
validate_flag_value "$ARGS" "-c or --single-commit" "commit hash"

# Extract the first argument that could be an issue reference
# Strip known flags to get the reference
REFERENCE=$(echo "$ARGS" | sed -E 's/(-l|--last|-sc|--since-commit|-c|--single-commit)(\s+[^ ]*)?//g' | xargs | awk '{print $1}')
log_debug "REFERENCE" "$REFERENCE"

PARSE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/issues/parse-references.sh"
ISSUE_NUM=""

# Try parsing from args first
if [[ -n "$REFERENCE" ]]; then
  PARSE_RESULT=$(bash "$PARSE_SCRIPT" "$REFERENCE" 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    ISSUE_NUM=$(echo "$PARSE_RESULT" | jq -r '.issue_number')
  fi
fi

# Fallback: try parsing from branch name
if [[ -z "$ISSUE_NUM" ]] || [[ "$ISSUE_NUM" == "null" ]]; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "")
  if [[ -n "$BRANCH" ]]; then
    PARSE_RESULT=$(bash "$PARSE_SCRIPT" "$BRANCH" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ISSUE_NUM=$(echo "$PARSE_RESULT" | jq -r '.issue_number')
    fi
  fi
fi

# Fallback: check metadata linkedIssue
if [[ -z "$ISSUE_NUM" ]] || [[ "$ISSUE_NUM" == "null" ]]; then
  if [[ -f "$METADATA_FILE" ]]; then
    LINKED=$(yq -r '.linkedIssue // ""' "$METADATA_FILE" 2>/dev/null)
    if [[ -n "$LINKED" ]] && [[ "$LINKED" != "null" ]]; then
      ISSUE_NUM="$LINKED"
    fi
  fi
fi

log_debug "ISSUE_NUM" "$ISSUE_NUM"

if [[ -z "$ISSUE_NUM" ]] || [[ "$ISSUE_NUM" == "null" ]]; then
  log_error "No issue number provided"
  log_exit 2 "no issue number"
  echo "Error: No issue number provided" >&2
  exit 2
fi

# Check issue exists
log_info "Checking if issue #$ISSUE_NUM exists..."
if ! gh issue view "$ISSUE_NUM" &>/dev/null; then
  log_error "Issue #$ISSUE_NUM not found"
  log_exit 2 "issue not found"
  echo "Error: Issue #$ISSUE_NUM not found" >&2
  exit 2
fi

log_info "Issue #$ISSUE_NUM validated"

# Inject the parsed issue number as context
source "$SCRIPTS_DIR/lib/hook-output.sh"
hook_output_context "<parsed-issue>$ISSUE_NUM</parsed-issue>"
exit 0
