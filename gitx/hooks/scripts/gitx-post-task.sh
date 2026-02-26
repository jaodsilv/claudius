#!/bin/bash
# PostToolUse dispatcher for gitx agents invoked via Task tool
# Minimal pass-through (no Task-specific post-handling exists today)
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export GITX_DEBUG=1          # Enable debug logging
# export GITX_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source libraries
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
LIBS_DIR="${SCRIPTS_DIR}/lib"

# Plugin config (set BEFORE sourcing shared libs)
export HOOK_PLUGIN_NAME="GITX"

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "post-task"

# PostToolUse event
export HOOK_EVENT_TYPE="PostToolUse"

# Read input and extract agent type
_RAW_INPUT=$(cat)
_AGENT_TYPE=$(echo "$_RAW_INPUT" | jq -r '.tool_input.subagent_type // ""')

# Early exit if not a gitx agent
if [[ "$_AGENT_TYPE" != gitx:* ]]; then
  log_exit 0 "non-gitx agent - pass through"
  exit 0
fi

log_info "Post-task for $_AGENT_TYPE - pass through"
log_exit 0 "pass through"
exit 0
