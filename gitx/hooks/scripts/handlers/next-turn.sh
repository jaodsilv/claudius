#!/bin/bash
# Handler for /gitx:next-turn command
# Wait for CI, refresh metadata (which computes turn correctly), output result

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Next-Turn Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, blocking"
  log_exit 0 "no metadata - block"
  cat <<EOF
{"decision": "block", "reason": "No PR metadata. Run /gitx:pr to create a PR first."}
EOF
  exit 0
fi

TURN=$(yq -r '.turn' "$METADATA_FILE")

# Wait for CI using centralized operation (suppress stdout, errors go to stderr)
if [[ "$TURN" == "CI-PENDING" ]]; then
  log_debug "TURN" "$TURN"
  log_info "Waiting for CI to complete..."
  bash "${SCRIPTS_DIR}/handlers/metadata-operations.sh" wait-ci "$WORKTREE" >/dev/null
fi

# Refresh metadata - this computes turn correctly using statusCheckRollup
# which properly handles skipped jobs (unlike gh run list)
log_info "Refreshing metadata..."
bash "${SCRIPTS_DIR}/handlers/metadata-operations.sh" fetch "$WORKTREE" >/dev/null

# Build context for Claude using proper hookSpecificOutput format
TURN=$(yq -r '.turn' "$METADATA_FILE")
PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
log_debug "TURN" "$TURN"
log_exit 0 "turn updated"

# Use hookSpecificOutput.additionalContext for proper context injection
# next-turn does not need to know extra information beyond the turn.
hook_output_context "--turn $TURN"
exit 0
