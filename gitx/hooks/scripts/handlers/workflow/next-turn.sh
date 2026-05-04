#!/bin/bash
# Handler for /gitx:next-turn command
# Wait for CI, refresh metadata (which computes turn correctly), output result

source "$SCRIPTS_DIR/lib/hook-output.sh"
source "$SCRIPTS_DIR/lib/args-validator.sh"
log_section "Next-Turn Handler"

NO_METADATA_SYNC=false
if has_flag "$ARGS" "--no-metadata-sync"; then
  NO_METADATA_SYNC=true
fi
log_debug "NO_METADATA_SYNC" "$NO_METADATA_SYNC"

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
if [[ "$TURN" == "CI-PENDING" && "$NO_METADATA_SYNC" == "false" ]]; then
  log_debug "TURN" "$TURN"
  log_info "Waiting for CI to complete..."
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --wait-ci >/dev/null
fi

# Refresh metadata - this computes turn correctly using statusCheckRollup
# which properly handles skipped jobs (unlike gh run list)
if [[ "$NO_METADATA_SYNC" == "false" ]]; then
  log_info "Refreshing metadata..."
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --refresh >/dev/null
else
  log_info "Skipping metadata refresh (--no-metadata-sync)"
fi

# Build context for Claude using proper hookSpecificOutput format
TURN=$(yq -r '.turn' "$METADATA_FILE")
PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
log_debug "TURN" "$TURN"
log_exit 0 "turn updated"

# Use hookSpecificOutput.additionalContext for proper context injection
# next-turn does not need to know extra information beyond the turn.
hook_output_context "<worktree>$WORKTREE</worktree>
--turn $TURN"
exit 0
