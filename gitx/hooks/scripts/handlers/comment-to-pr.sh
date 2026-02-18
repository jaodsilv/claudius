#!/bin/bash
# Handler for /gitx:comment-to-pr command
# Validate PR exists and block if wrong turn (require --force to override)

# Source args validator
source "$SCRIPTS_DIR/lib/args-validator.sh"

log_section "Comment-to-PR Handler"
log_debug "ARGS" "$ARGS"

# Validate mutually exclusive comment source flags
# Pattern: [<comment> | -l or --last | -sc or --since-commit <hash> | (-c or --single-commit) <hash>]
validate_mutually_exclusive "$ARGS" "-l or --last" "-sc or --since-commit" "-c or --single-commit"

# Validate mutually exclusive review flags
# Pattern: [-r or --review | -rr or --review-response [<text>]]
validate_mutually_exclusive "$ARGS" "-r or --review" "-rr or --review-response"

# Validate -sc requires hash value
validate_flag_value "$ARGS" "-sc or --since-commit" "commit hash"

# Validate -c requires hash value
validate_flag_value "$ARGS" "-c or --single-commit" "commit hash"

# Check for --force flag using has_flag
FORCE=false
if has_flag "$ARGS" "-f or --force"; then
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
    if [[ "$TURN" == "CI-REVIEW" ]] || [[ "$TURN" == "CI-PENDING" ]] || [[ "$TURN" == "AUTHOR" ]]; then
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
      log_exit 0 "Block: Wrong turn for comment"
      hook_output_block "Cannot post comment during REVIEW turn"
    fi
  fi
fi

# Already processed arguments:

# Group 1: PR number or worktree path, positional arguments. Define which PR the comment should be posted to.
# Group 2: --force or -f flag, overrides validation
# If --force or -f is present, the comment will be posted without validation. Already processed.

# Group 3: -r or -rr, defines the type of comment to be posted, and part of HOW the comment should be written
# They are mutually exclusive and define what type of comment should be used. Default to -rr
# If -r or --review is present, The post must be a review comment. To be posted with `gh pr review`
# If -rr or --review-response is present, The post must be either:
  # A review comment response if it comes from a review thread,
  # or a standard comment if it is about a global review comment. To be posted with `gh pr comment`

# Group 4: Comment text positional argument or -l or -c or -sc, define HOW the comment should be written
# They are mutually exclusive
# If comment text is present, we can post it directly and we are done.
# If -l or --last we need the LLM to fetch the correct options and present to the user.
# If -c or --commit we need the LLM to write the comment message, but we can fetch the commit message body for them.
#    This argument must be followed by a commit hash.
# If -sc or --since-commit we need the LLM to write the comment message, but we can fetch the commit range for them.
#    This argument must be followed by one or two commit hashes.
#    When 2 commit hashes are provided, they represent the range of commits to summarize.

# We should post the comment to the PR directly from here if Comment text is present

# We must fetch the commit log for the LLM if -c or --commit is present
# We must fetch the commit log range for the LLM if -sc or --since-commit is present

log_info "PR #$PR_NUM validated, proceeding"
hook_output_context "<worktree>$WORKTREE</worktree>
PR: $PR_NUM
Turn: $TURN"
echo "PR #$PR_NUM validated. Proceeding."
log_exit 0 "PR validated"
exit 0
