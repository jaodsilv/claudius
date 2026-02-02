#!/bin/bash
# PreToolUse dispatcher for cc skills
# Handles validation and setup when cc skills are invoked via Skill tool
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export CC_DEBUG=1          # Enable debug logging
# export CC_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source logging
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/args-validator.sh"
log_init "pre-tool"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="PreToolUse"

# Read JSON input from stdin
INPUT=$(cat)
log_section "Input Processing"
log_json "stdin_input" "$INPUT"

# Parse PreToolUse fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
log_debug "TOOL_NAME" "$TOOL_NAME"
log_debug "CWD" "$CWD"

# Only handle Skill tool invocations
if [[ "$TOOL_NAME" != "Skill" ]]; then
  log_info "Not a Skill tool call, passing through"
  log_exit 0 "not Skill tool"
  exit 0
fi

# Extract skill name from tool_input
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
log_debug "SKILL" "$SKILL"

# Only handle cc: prefixed skills
if [[ ! "$SKILL" =~ ^cc: ]]; then
  log_info "Not a cc skill, passing through"
  log_exit 0 "not cc skill"
  exit 0
fi

# Extract command name: cc:command-name -> command-name
COMMAND="${SKILL#cc:}"
ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
log_debug "COMMAND" "$COMMAND"
log_debug "ARGS" "$ARGS"

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

WORKTREE=$(convert_path "$CWD")
if [[ "$WORKTREE" == "." ]] || [[ -z "$WORKTREE" ]]; then
  WORKTREE=$(convert_path "$(pwd)")
fi

# Resolve relative paths to absolute
if [[ ! "$WORKTREE" = /* ]]; then
  WORKTREE=$(convert_path "$(cd "$WORKTREE" 2>/dev/null && pwd)")
fi
log_debug "WORKTREE (resolved)" "$WORKTREE"

# Export variables for handler scripts
export WORKTREE
export ARGS
export CC_DEBUG
export CC_LOG_VERBOSE
export CC_LOG_DIR

# Dispatch to command-specific handler
log_section "Handler Dispatch"
log_info "Dispatching to handler: $COMMAND"

HANDLERS_DIR="$SCRIPTS_DIR/handlers"

case "$COMMAND" in
  bump-version)
    log_info "Loading bump-version.sh"
    # Validate mutually exclusive flags: --commit | --no-commit
    validate_mutually_exclusive "$ARGS" "--commit" "--no-commit"
    source "$HANDLERS_DIR/bump-version.sh"
    ;;
  sync-configs)
    log_info "Loading sync-configs.sh"
    source "$HANDLERS_DIR/sync-configs.sh"
    ;;
  create-command|create-skill|create-orchestration|create-output-style)
    log_info "Validating create-* arguments"
    source "$HANDLERS_DIR/create-common.sh"
    ;;
  improve-agent|improve-command|improve-skill|improve-plugin|improve-orchestration|improve-output-style)
    log_info "Validating improve-* arguments"
    source "$HANDLERS_DIR/improve-common.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
