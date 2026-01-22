#!/bin/bash
# Handler for /gitx:merge-pr command
# Validate approved, merge PR, block always

log_section "Merge-PR Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, trying to get PR from current branch"
  # Try to get PR from current branch
  PR_NUM=$(gh pr view --json number --jq '.number' 2>/dev/null || echo "")
  log_debug "PR_NUM (from gh)" "$PR_NUM"

  if [[ -z "$PR_NUM" ]]; then
    log_error "No PR found for current branch"
    log_exit 2 "no PR"
    echo "Error: No PR found for current branch" >&2
    exit 2
  fi
  # Fetch metadata
  log_info "Fetching metadata..."
  bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"
fi

APPROVED=$(yq -r '.approved // false' "$METADATA_FILE")
PR_NUM=$(yq -r '.pr' "$METADATA_FILE")
log_debug "APPROVED" "$APPROVED"
log_debug "PR_NUM" "$PR_NUM"

if [[ "$APPROVED" != "true" ]]; then
  log_error "PR #$PR_NUM is not approved"
  log_exit 2 "not approved"
  echo "Error: PR #$PR_NUM is not approved. Get reviewer approval first." >&2
  exit 2
fi

# Merge the PR
log_info "Merging PR #$PR_NUM..."
gh pr merge "$PR_NUM" --merge --delete-branch
RESULT=$?
log_debug "MERGE_RESULT" "$RESULT"

if [[ $RESULT -eq 0 ]]; then
  log_info "PR merged successfully"
  echo "PR #$PR_NUM merged successfully!"
else
  log_error "Failed to merge PR"
  echo "Error: Failed to merge PR #$PR_NUM" >&2
fi

log_exit 2 "block always"
exit 2  # Block always - hook handles everything
