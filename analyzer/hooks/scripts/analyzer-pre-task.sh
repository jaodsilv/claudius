#!/bin/bash
# PreToolUse dispatcher for analyzer agents invoked via Agent tool
# Handles context injection for analyzer sub-agents
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
_RAW_INPUT=$(cat)
export CWD=$(echo "$_RAW_INPUT" | jq -r '.cwd // ""')

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/hook-output.sh"
source "$LIBS_DIR/args-validator.sh"
log_init "pre-task"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="PreToolUse"

_AGENT_TYPE=$(echo "$_RAW_INPUT" | jq -r '.tool_input.subagent_type // ""')

# Early exit if not an analyzer agent
if [[ "$_AGENT_TYPE" != analyzer:* ]]; then
  log_exit 0 "non-analyzer agent - pass through"
  exit 0
fi

log_section "Analyzer Agent"
log_debug "AGENT_TYPE" "$_AGENT_TYPE"

# Extract model for inject_or_read decisions (default: sonnet)
_AGENT_MODEL=$(echo "$_RAW_INPUT" | jq -r '.tool_input.model // "sonnet"')
log_debug "AGENT_MODEL" "$_AGENT_MODEL"

# Extract agent suffix: analyzer:analysis-splitter -> analysis-splitter
AGENT_SUFFIX="${_AGENT_TYPE#analyzer:}"
log_debug "AGENT_SUFFIX" "$AGENT_SUFFIX"

# Extract prompt from tool input
TOOL_INPUT=$(echo "$_RAW_INPUT" | jq -r '.tool_input // {}')
PROMPT=$(echo "$TOOL_INPUT" | jq -r '.prompt // ""')

case "$AGENT_SUFFIX" in
  # ── analysis-splitter ──────────────────────────────────────────────
  analysis-splitter)
    WORKTREE=$(get_xml_value "$PROMPT" "worktree")
    if [[ -z "$WORKTREE" ]]; then
      log_error "No <worktree> found in prompt"
      hook_output_block "Missing <worktree> in agent prompt"
      exit 0
    fi

    ANALYSIS_PATH=$(get_xml_value "$PROMPT" "analysis-path")
    [[ -z "$ANALYSIS_PATH" ]] && ANALYSIS_PATH="$WORKTREE/.thoughts/analyzer/full-analysis.md"

    if [[ ! -f "$ANALYSIS_PATH" ]]; then
      log_error "Analysis file not found: $ANALYSIS_PATH"
      hook_output_block "Analysis file not found: $ANALYSIS_PATH"
      exit 0
    fi

    log_info "Injecting analysis for splitting"
    ANALYSIS_CONTENT=$(inject_or_read "$ANALYSIS_PATH" "analysis" "$_AGENT_MODEL")
    hook_output_context "$ANALYSIS_CONTENT"
    ;;

  # ── analyses-merger ────────────────────────────────────────────────
  analyses-merger)
    WORKTREE=$(get_xml_value "$PROMPT" "worktree")
    if [[ -z "$WORKTREE" ]]; then
      log_error "No <worktree> found in prompt"
      hook_output_block "Missing <worktree> in agent prompt"
      exit 0
    fi

    ANALYSIS_PATHS=$(get_xml_value "$PROMPT" "analysis-paths")
    if [[ -z "$ANALYSIS_PATHS" ]]; then
      log_error "No <analysis-paths> found in prompt"
      hook_output_block "Missing <analysis-paths> in agent prompt"
      exit 0
    fi

    COUNTER=1
    CONTEXT=""
    for path in $ANALYSIS_PATHS; do
      if [[ ! -f "$path" ]]; then
        log_error "Analysis file not found: $path"
        hook_output_block "Analysis file not found: $path"
        exit 0
      fi
      ANALYSIS_CONTENT=$(inject_or_read "$path" "analysis-$COUNTER" "$_AGENT_MODEL")
      CONTEXT+="$ANALYSIS_CONTENT
"
      ((COUNTER++))
    done

    log_info "Injecting $((COUNTER - 1)) analyses for merging"
    hook_output_context "$CONTEXT"
    ;;

  # ── adversarial-critic ─────────────────────────────────────────────
  adversarial-critic)
    INPUT_PATH=$(get_xml_value "$PROMPT" "input-path")
    if [[ -n "$INPUT_PATH" ]] && [[ -f "$INPUT_PATH" ]]; then
      log_info "Injecting input content for critique"
      INPUT_CONTENT=$(inject_or_read "$INPUT_PATH" "input-content" "$_AGENT_MODEL")
      hook_output_context "$INPUT_CONTENT"
    else
      log_info "No input-path provided or file not found, passing through"
      log_exit 0 "pass through"
      exit 0
    fi
    ;;

  # ── unknown agent ──────────────────────────────────────────────────
  *)
    log_info "No context injection for analyzer agent: $AGENT_SUFFIX"
    log_exit 0 "pass through"
    exit 0
    ;;
esac

log_exit 0 "context injected"
exit 0
