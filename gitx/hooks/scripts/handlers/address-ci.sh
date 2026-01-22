#!/bin/bash
# Handler for /gitx:address-ci command
# Wait for CI, update turn, block if not CI-REVIEW

log_section "Address-CI Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata found. Create a PR first with /gitx:pr" >&2
  exit 2
fi

BRANCH=$(yq -r '.branch' "$METADATA_FILE")
log_debug "BRANCH" "$BRANCH"

# Wait for CI (poll every 10 seconds, max 10 minutes)
log_info "Waiting for CI to complete..."
MAX_WAIT=600
ELAPSED=0
while [[ $ELAPSED -lt $MAX_WAIT ]]; do
  PENDING=$(gh run list -b "$BRANCH" --json status --jq '[.[] | select(.status != "completed")] | length' || echo "0")
  log_debug "PENDING_CHECKS" "$PENDING"
  if [[ "$PENDING" == "0" ]]; then
    log_info "All CI checks completed"
    break
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

# Refresh metadata
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"

# Check CI status
FAILED=$(gh run list -b "$BRANCH" --json conclusion --jq '[.[] | select(.conclusion == "failure")] | length' || echo "0")
log_debug "FAILED_CHECKS" "$FAILED"

if [[ "$FAILED" -gt 0 ]]; then
  log_info "CI has $FAILED failed checks, setting turn to CI-REVIEW"
  bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "CI-REVIEW"
  # Output context for Claude
  echo "CI Status: $FAILED failed checks. Proceed with /gitx:address-ci"
  log_exit 0 "CI failures to address"
  exit 0
else
  log_info "All CI passed, setting turn to REVIEW"
  bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "REVIEW"
  echo "All CI checks passed. No failures to address." >&2
  log_exit 2 "all CI passed - blocking"
  exit 2  # Block
fi
