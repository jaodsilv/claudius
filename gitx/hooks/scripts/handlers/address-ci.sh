#!/bin/bash
# Handler for /gitx:address-ci command
# Wait for CI, refresh metadata (which computes turn correctly), block if not CI-REVIEW

log_section "Address-CI Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata found. Create a PR first with /gitx:pr" >&2
  exit 2
fi

# Wait for CI using centralized operation
log_info "Waiting for CI to complete..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" wait-ci "$WORKTREE"

# Refresh metadata - this computes turn correctly using statusCheckRollup
# which properly handles skipped jobs (unlike gh run list)
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"

# Trust the turn from the refreshed metadata
TURN=$(yq -r '.turn' "$METADATA_FILE")
log_debug "TURN" "$TURN"

if [[ "$TURN" == "CI-REVIEW" ]]; then
  # Count failing checks from metadata for context message
  FAILED=$(yq -r '[.ciStatus[] | select(.conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "CANCELLED" and .conclusion != "NEUTRAL" and .conclusion != null and .conclusion != "")] | length' "$METADATA_FILE")
  log_info "CI has $FAILED failed checks"
  echo "CI Status: $FAILED failed checks. Proceed with /gitx:address-ci"
  log_exit 0 "CI failures to address"
  exit 0
else
  log_info "Turn is $TURN - no CI failures to address"
  log_exit 0 "all CI passed - block with JSON"
  echo "{\"decision\": \"block\", \"reason\": \"Turn is $TURN. No CI failures to address.\"}"
  exit 0
fi
