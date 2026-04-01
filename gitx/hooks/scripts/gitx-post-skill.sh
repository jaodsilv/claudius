#!/bin/bash
# PostToolUse dispatcher for gitx skills
# Handles looping for next-turn and address-ci commands
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

# Plugin config (set BEFORE sourcing shared libs)
export HOOK_PLUGIN_NAME="GITX"
export _PLUGIN_VALUE_FLAGS=(--worktree --base --files --context --resolve-level --format --session-path -l -a -t -m -sc -c --since-commit --single-commit)

# Read input and export CWD before logging init
INPUT=$(cat)
export CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-helper.sh"
source "$SCRIPTS_DIR/gitx-helpers.sh"
source "$LIBS_DIR/args-validator.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "post-skill"

# PostToolUse event - has tool_input field
export HOOK_EVENT_TYPE="PostToolUse"

init

NEXT_TURN=""
# Dispatch based on command
log_section "Command Dispatch"
case "$COMMAND" in
  address-ci)
    log_section "Address-CI Stop Hook"

    # Set turn to CI-PENDING (waiting for new CI run on pushed fixes)
    NEXT_TURN="CI-PENDING"
    ;;
  review)
    log_section "Review Stop Hook"

    # Post review to PR and update metadata
    source "$HANDLERS_DIR/reviews/post-review.sh"

    # Set turn to AUTHOR (waiting for author to read and respond to the review)
    NEXT_TURN="AUTHOR"
    ;;
  address-review)
    log_section "Address-Review Stop Hook"

    # Set turn to CI-PENDING (waiting for new CI run on pushed fixes)
    NEXT_TURN="CI-PENDING"
    ;;
  *)
    log_info "Not a looping command: $COMMAND"
    log_exit 0 "no loop needed"
    exit 0
    ;;
esac

bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --set turn "$NEXT_TURN"
log_exit 0 "Turn set to $NEXT_TURN"
exit 0
