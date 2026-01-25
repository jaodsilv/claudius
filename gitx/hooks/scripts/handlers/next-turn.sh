#!/bin/bash
# Handler for /gitx:next-turn command
# Wait for CI, refresh metadata (which computes turn correctly), output result
# Stop hook handles restart loop

log_section "Next-Turn Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, blocking"
  log_exit 0 "no metadata - block"
  cat <<EOF
{"decision": "block", "reason": "No PR metadata. Run /gitx:pr to create a PR first."}
EOF
  exit 0
fi

# Wait for CI using centralized operation (suppress stdout, errors go to stderr)
log_info "Waiting for CI to complete..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" wait-ci "$WORKTREE" >/dev/null

# Refresh metadata - this computes turn correctly using statusCheckRollup
# which properly handles skipped jobs (unlike gh run list)
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE" >/dev/null

# Build context for Claude using proper hookSpecificOutput format
TURN=$(yq -r '.turn' "$METADATA_FILE")
PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
log_debug "FINAL_TURN" "$TURN"
log_exit 0 "turn updated"

# Use hookSpecificOutput.additionalContext for proper context injection
cat <<EOF
{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "Turn: $TURN | PR: $PR | Branch: $BRANCH | Worktree: $WORKTREE"}}
EOF
exit 0
