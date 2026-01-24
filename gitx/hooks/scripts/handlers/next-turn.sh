#!/bin/bash
# Handler for /gitx:next-turn command
# Wait for CI, update turn (Stop hook handles restart loop)

log_section "Next-Turn Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, letting command handle"
  echo "No PR metadata. Run /gitx:pr to create a PR first."
  log_exit 0 "no metadata - pass through"
  exit 0
fi

BRANCH=$(yq -r '.branch' "$METADATA_FILE")
log_debug "BRANCH" "$BRANCH"

# Wait for CI
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

# Update turn based on CI and review state
# Only check the LATEST run per workflow (not old failed runs that have been re-run)
FAILED=$(gh run list -b "$BRANCH" --json conclusion,workflowName \
  | jq -r 'group_by(.workflowName) | map(.[0]) | [.[] | select(.conclusion == "failure")] | length' \
  || echo "0")
log_debug "FAILED_CHECKS" "$FAILED"

REVIEW_DECISION=$(yq -r '.reviewDecision // ""' "$METADATA_FILE")
log_debug "REVIEW_DECISION" "$REVIEW_DECISION"

UNRESOLVED_THREADS=$(yq -r '.reviewThreads[] | select(.isResolved == false)' "$METADATA_FILE" 2>/dev/null || echo "")
log_debug "HAS_UNRESOLVED_THREADS" "$(test -n \"$UNRESOLVED_THREADS\" && echo \"yes\" || echo \"no\")"

if [[ "$FAILED" -gt 0 ]]; then
  log_info "Setting turn to CI-REVIEW (CI failures)"
  bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "CI-REVIEW"
elif [[ -n "$UNRESOLVED_THREADS" ]]; then
  log_info "Setting turn to AUTHOR (unresolved threads)"
  bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "AUTHOR"
else
  log_info "Setting turn to REVIEW"
  bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "REVIEW"
fi

# Output updated turn for context
TURN=$(yq -r '.turn' "$METADATA_FILE")
log_debug "FINAL_TURN" "$TURN"
echo "Turn updated: $TURN"
log_exit 0 "turn updated"
exit 0
