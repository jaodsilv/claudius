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
    ;;

  "/gitx:address-ci")
    log_section "Address-CI Loop Check"

    # Loop until all CI passes
    BRANCH=$(yq -r '.branch' "$METADATA_FILE")
    log_debug "BRANCH" "$BRANCH"

    # Wait for CI to complete
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
      log_debug "ELAPSED_SECONDS" "$ELAPSED"
    done

    # Check CI status
    FAILED=$(gh run list -b "$BRANCH" --json conclusion --jq '[.[] | select(.conclusion == "failure")] | length' || echo "0")
    log_debug "FAILED_CHECKS" "$FAILED"

    if [[ "$FAILED" -gt 0 ]]; then
      log_info "CI has $FAILED failed checks, continuing loop"

      # Refresh metadata with new CI data
      bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"
      bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "CI-REVIEW"

      log_exit 0 "continue loop - CI failures"
      cat <<EOF
{
  "decision": "block",
  "reason": "CI still has $FAILED failed checks. Continuing address-ci loop. Fix the failures and run /gitx:address-ci."
}
EOF
    else
      log_info "All CI passed, updating turn to REVIEW"

      # All CI passed - update turn to REVIEW and stop
      bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"
      bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" set-turn "$WORKTREE" "REVIEW"

      log_exit 0 "CI passed"
      exit 0
    fi
    ;;

  *)
    log_info "Not a looping command"
    log_exit 0 "no loop needed"
    exit 0
    ;;
esac
