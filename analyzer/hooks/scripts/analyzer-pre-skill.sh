#!/bin/bash
# PreToolUse dispatcher for analyzer skills
# Handles validation and setup when analyzer skills are invoked via Skill tool
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export ANALYZER_DEBUG=1          # Enable debug logging
# export ANALYZER_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source libraries
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
export HANDLERS_DIR="${SCRIPTS_DIR}/handlers"
LIBS_DIR="${SCRIPTS_DIR}/lib"

# Plugin config (set BEFORE sourcing shared libs)
HOOK_PLUGIN_NAME="ANALYZER"
_PLUGIN_VALUE_FLAGS=(--worktree --input-type --analysis-path --analysis-paths --input-path)

# Read input and export CWD before logging init
INPUT=$(cat)
export CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-helper.sh"
source "$SCRIPTS_DIR/analyzer-helpers.sh"
source "$LIBS_DIR/args-validator.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "pre-skill"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="PreToolUse"

init

# Dispatch to command-specific handler
log_section "Handler Dispatch"
log_info "Dispatching to handler: $COMMAND"

case "$COMMAND" in
  analyze)
    log_info "Loading analyze.sh"
    source "$HANDLERS_DIR/analyze.sh"
    ;;
  split-analysis)
    log_info "Loading split-analysis.sh"
    source "$HANDLERS_DIR/split-analysis.sh"
    ;;
  challenge)
    log_info "Loading challenge.sh"
    source "$HANDLERS_DIR/challenge.sh"
    ;;
  merge-analyses)
    log_info "Loading merge-analyses.sh"
    source "$HANDLERS_DIR/merge-analyses.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
