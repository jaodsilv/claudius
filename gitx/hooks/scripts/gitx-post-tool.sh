#!/bin/bash
# PostToolUse/Stop dual-mode dispatcher for gitx skills
# Handles looping for next-turn and address-ci commands
#
# Detection:
#   - tool_input present → PostToolUse event
#   - transcript_path present → Stop event
#
# Output format:
#   - Stop: {"decision": "block", "reason": "..."}
#   - PostToolUse: {"decision": "block", "reason": "...", "hookSpecificOutput": {...}}
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export GITX_DEBUG=1          # Enable debug logging
# export GITX_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source libraries
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
export HANDLERS_DIR="${SCRIPTS_DIR}/handlers"
LIBS_DIR="${SCRIPTS_DIR}/lib"
source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-helper.sh"
source "$LIBS_DIR/args-validator.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "post-tool"

# PostToolUse event - has tool_input field
export HOOK_EVENT_TYPE="PostToolUse"

init

$NEXT_TURN = ""
# Dispatch based on command
log_section "Command Dispatch"
case "$COMMAND" in
  address-ci)
    log_section "Address-CI Stop Hook"

    # Set turn to CI-PENDING (waiting for new CI run on pushed fixes)
    $NEXT_TURN = "CI-PENDING"
    ;;
  review)
    log_section "Review Stop Hook"

    # Set turn to AUTHOR (waiting for author to read and respond to the review)
    $NEXT_TURN = "AUTHOR"
    ;;
  address-review)
    log_section "Address-Review Stop Hook"

    # Set turn to CI-PENDING (waiting for new CI run on pushed fixes)
    $NEXT_TURN = "CI-PENDING"
    ;;
  *)
    log_info "Not a looping command: $COMMAND"
    log_exit 0 "no loop needed"
    exit 0
    ;;
esac

bash "$HANDLERS_DIR/metadata-operations.sh" set-turn "$WORKTREE" "$NEXT_TURN"
log_exit 0 "Turn set to $NEXT_TURN"
exit 0
