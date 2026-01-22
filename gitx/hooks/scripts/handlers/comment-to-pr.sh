#!/bin/bash
# Handler for /gitx:comment-to-pr command
# Validate PR exists and block if wrong turn (require --force to override)

log_section "Comment-to-PR Handler"
log_debug "ARGS" "$ARGS"

# Check for --force flag
FORCE=false
if [[ "$ARGS" =~ --force|-f ]]; then
  FORCE=true
fi
log_debug "FORCE" "$FORCE"

# Get PR number from args or metadata
PR_NUM=""
if [[ "$ARGS" =~ ^([0-9]+) ]]; then
  PR_NUM="${BASH_REMATCH[1]}"
elif [[ -f "$METADATA_FILE" ]]; then
  PR_NUM=$(yq -r '.pr' "$METADATA_FILE")
fi
log_debug "PR_NUM" "$PR_NUM"

if [[ -z "$PR_NUM" ]] || [[ "$PR_NUM" == "null" ]]; then
  log_error "No PR number found"
  log_exit 2 "no PR number"
  echo "Error: No PR number found" >&2
  exit 2
fi

# Validate PR exists
log_info "Checking if PR #$PR_NUM exists..."
if ! gh pr view "$PR_NUM" &>/dev/null; then
  log_error "PR #$PR_NUM not found"
  log_exit 2 "PR not found"
  echo "Error: PR #$PR_NUM not found" >&2
  exit 2
fi
log_info "PR #$PR_NUM exists"

# Check turn and block if wrong (unless --force)
if [[ -f "$METADATA_FILE" ]] && [[ "$FORCE" == "false" ]]; then
  TURN=$(yq -r '.turn // "unknown"' "$METADATA_FILE")
  log_debug "TURN" "$TURN"

  # Check if -r/--review flag present
  if [[ "$ARGS" =~ -r[[:space:]]|--review ]]; then
    log_debug "COMMENT_TYPE" "review"
    # Review comment - should only post during REVIEW turn
    if [[ "$TURN" == "CI-REVIEW" ]] || [[ "$TURN" == "AUTHOR" ]]; then
      log_warn "Cannot post review comment during $TURN turn"
      log_exit 2 "wrong turn for review"
      echo "Error: Cannot post review comment during $TURN turn (expected REVIEW)." >&2
      echo "Use --force to override." >&2
      exit 2
    fi
  else
    log_debug "COMMENT_TYPE" "normal"
    # Normal comment - should not post during REVIEW turn (that's reviewer's turn)
    if [[ "$TURN" == "REVIEW" ]]; then
      log_warn "Cannot post comment during REVIEW turn"
      log_exit 2 "wrong turn for comment"
      echo "Error: Cannot post comment during REVIEW turn (reviewer's turn)." >&2
      echo "Use --force to override." >&2
      exit 2
    fi
  fi
fi

log_info "PR #$PR_NUM validated, proceeding"
echo "PR #$PR_NUM validated. Proceeding."
log_exit 0 "PR validated"
exit 0
