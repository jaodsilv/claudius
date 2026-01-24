#!/bin/bash
# Handler for /gitx:next-turn command
# Wait for CI, refresh metadata (which computes turn correctly), output result
# Stop hook handles restart loop

log_section "Next-Turn Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, letting command handle"
  echo "No PR metadata. Run /gitx:pr to create a PR first."
  log_exit 0 "no metadata - pass through"
  exit 0
fi

# Wait for CI using centralized operation
log_info "Waiting for CI to complete..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" wait-ci "$WORKTREE"

# Refresh metadata - this computes turn correctly using statusCheckRollup
# which properly handles skipped jobs (unlike gh run list)
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"

# Output updated turn for context (trust the value from fetch)
TURN=$(yq -r '.turn' "$METADATA_FILE")
log_debug "FINAL_TURN" "$TURN"
echo "Turn updated: $TURN"
log_exit 0 "turn updated"
exit 0
