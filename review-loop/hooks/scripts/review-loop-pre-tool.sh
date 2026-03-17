#!/bin/bash
# PreToolUse dispatcher for review-loop skills
# Handles validation and setup when review-loop skills are invoked via Skill tool
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export REVIEW_LOOP_DEBUG=1          # Enable debug logging
# export REVIEW_LOOP_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source libraries
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
export HANDLERS_DIR="${SCRIPTS_DIR}/handlers"
LIBS_DIR="${SCRIPTS_DIR}/lib"

# Plugin config (set BEFORE sourcing shared libs)
HOOK_PLUGIN_NAME="REVIEW_LOOP"

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-helper.sh"
source "$SCRIPTS_DIR/review-loop-helpers.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "pre-tool"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="PreToolUse"

init

# Dispatch to command-specific handler
log_section "Handler Dispatch"
log_info "Dispatching to handler: $COMMAND"

case "$COMMAND" in
  start-loop)
    log_info "Loading start-loop.sh"
    source "$HANDLERS_DIR/start-loop.sh"
    ;;
  resume-loop)
    log_info "Loading resume-loop.sh"
    source "$HANDLERS_DIR/resume-loop.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
