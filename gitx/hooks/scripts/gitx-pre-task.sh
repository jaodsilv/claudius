#!/bin/bash
# PreToolUse dispatcher for gitx agents invoked via Agent tool
# Handles metadata injection and context setup for gitx sub-agents
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

# Read input and export CWD before logging init
_RAW_INPUT=$(cat)
export CWD=$(echo "$_RAW_INPUT" | jq -r '.cwd // ""')

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "pre-task"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="PreToolUse"

_AGENT_TYPE=$(echo "$_RAW_INPUT" | jq -r '.tool_input.subagent_type // ""')

log_debug "AGENT_TYPE" "$_AGENT_TYPE"

# Early exit if not a gitx agent
if [[ "$_AGENT_TYPE" != gitx:* ]]; then
  log_exit 0 "non-gitx agent - pass through"
  exit 0
fi

log_section "Gitx Agent"

case "$_AGENT_TYPE" in
  gitx:address-review:review-responder|gitx:address-review:ci-status-checker|gitx:pr:updater)
    log_info "Routing to inject-pr-metadata handler"
    bash "$HANDLERS_DIR/inject-pr-metadata.sh" "$_RAW_INPUT"
    exit $?
    ;;
  gitx:ci:*)
    log_info "Routing to ci-pre-tool handler for $_AGENT_TYPE"
    bash "$HANDLERS_DIR/ci-pre-tool.sh" "$_AGENT_TYPE" "$_RAW_INPUT"
    exit $?
    ;;
  gitx:issue:fix-orchestrator)
    log_info "Parsing issue reference for fix-orchestrator"
    # Extract potential issue reference from agent prompt
    _PROMPT=$(echo "$_RAW_INPUT" | jq -r '.tool_input.prompt // ""')
    # Try to parse any issue reference from the prompt
    PARSE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/issues/parse-references.sh"
    if [[ -f "$PARSE_SCRIPT" ]]; then
      # Try each word in the prompt as a potential reference
      PARSE_RESULT=""
      for word in $_PROMPT; do
        PARSE_RESULT=$(bash "$PARSE_SCRIPT" "$word" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
          break
        fi
        PARSE_RESULT=""
      done
      if [[ -n "$PARSE_RESULT" ]]; then
        source "$LIBS_DIR/hook-output.sh"
        hook_output_context "<parsed-issue-reference>$PARSE_RESULT</parsed-issue-reference>"
      fi
    fi
    exit 0
    ;;
  *)
    log_info "No metadata injection for $_AGENT_TYPE - pass through"
    log_exit 0 "pass through"
    exit 0
    ;;
esac
