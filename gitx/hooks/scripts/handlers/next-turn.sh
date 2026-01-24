#!/bin/bash
# Handler for /gitx:next-turn command
# Wait for CI, refresh metadata (which computes turn correctly), output result
# Stop hook handles restart loop

log_section "Next-Turn Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, letting command handle"
  log_exit 0 "no metadata - block with JSON"
  echo '{"decision": "block", "reason": "No PR metadata. Run /gitx:pr to create a PR first.", "turn": "NO_METADATA"}'
  exit 0
fi

# Wait for CI using centralized operation (suppress stdout, errors go to stderr)
log_info "Waiting for CI to complete..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" wait-ci "$WORKTREE" >/dev/null

# Refresh metadata - this computes turn correctly using statusCheckRollup
# which properly handles skipped jobs (unlike gh run list)
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE" >/dev/null

# Output single JSON with turn info
TURN=$(yq -r '.turn' "$METADATA_FILE")
PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
log_debug "FINAL_TURN" "$TURN"
log_exit 0 "turn updated"
echo "{\"turn\": \"$TURN\", \"pr\": $PR, \"branch\": \"$BRANCH\", \"worktree\": \"$WORKTREE\"}"
exit 0
