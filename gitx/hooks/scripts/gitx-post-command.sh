#!/bin/bash
# Stop hook for post-execution behavior
# Handles looping for next-turn and address-ci commands
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export GITX_DEBUG=1          # Enable debug logging
# export GITX_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
log_init "post-command"

# Read JSON input
INPUT=$(cat)
log_section "Input Processing"
log_json "stdin_input" "$INPUT"

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
log_debug "TRANSCRIPT_PATH" "$TRANSCRIPT_PATH"

if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  log_info "No transcript path or file not found, exiting"
  log_exit 0 "no transcript"
  exit 0
fi

# Convert Windows paths to bash format
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

WORKTREE="${CLAUDE_PROJECT_DIR:-.}"
WORKTREE=$(convert_path "$WORKTREE")
METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"

log_debug "WORKTREE" "$WORKTREE"
log_debug "METADATA_FILE" "$METADATA_FILE"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata file, exiting"
  log_exit 0 "no metadata"
  exit 0
fi

# Detect which gitx command was last run
log_section "Command Detection"
LAST_COMMAND=$(tail -100 "$TRANSCRIPT_PATH" | grep -oE '/gitx:(next-turn|address-ci)' | tail -1 || echo "")
log_debug "LAST_COMMAND" "$LAST_COMMAND"

case "$LAST_COMMAND" in
  "/gitx:next-turn")
    log_section "Next-Turn Loop Check"

    # Loop until PR is approved
    APPROVED=$(yq -r '.approved // false' "$METADATA_FILE")
    log_debug "APPROVED" "$APPROVED"

    if [[ "$APPROVED" == "true" ]]; then
      log_info "PR is approved, stopping loop"
      log_exit 0 "PR approved"
      exit 0
    fi

    log_info "PR not approved, requesting loop continuation"
    log_exit 0 "continue loop"
    cat <<EOF
{
  "decision": "block",
  "reason": "PR not yet approved. Continuing next-turn loop. Run /gitx:next-turn to check status."
}
EOF
    exit 0
    ;;

  "/gitx:address-ci")
    log_section "Address-CI Stop Hook"

    # Set turn to CI-PENDING (waiting for new CI run on pushed fixes)
    bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "CI-PENDING"
    log_info "Turn set to CI-PENDING"

    # Check if this was triggered within a next-turn loop
    # Look for /gitx:next-turn earlier in transcript
    IN_NEXT_TURN_LOOP=$(grep -c '/gitx:next-turn' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
    log_debug "IN_NEXT_TURN_LOOP" "$IN_NEXT_TURN_LOOP"

    if [[ "$IN_NEXT_TURN_LOOP" -gt 0 ]]; then
      log_info "In next-turn loop, continuing loop"
      log_exit 0 "continue loop - in next-turn"
      cat <<EOF
{
  "decision": "block",
  "reason": "CI-PENDING. Continuing next-turn loop to wait for CI results."
}
EOF
      exit 0
    else
      log_info "Direct invocation, stopping"
      log_exit 0 "turn set to CI-PENDING"
      exit 0
    fi
    ;;

  *)
    log_info "Not a looping command"
    log_exit 0 "no loop needed"
    exit 0
    ;;
esac
