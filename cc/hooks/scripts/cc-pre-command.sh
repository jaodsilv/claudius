#!/bin/bash
# Main dispatcher for UserPromptSubmit hook
# Handles validation and setup for all /cc:* commands
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export CC_DEBUG=1          # Enable debug logging
# export CC_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
log_init "pre-command"

# Read JSON input from stdin
INPUT=$(cat)
log_section "Input Processing"
log_json "stdin_input" "$INPUT"

PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
log_debug "PROMPT" "$PROMPT"
log_debug "CWD" "$CWD"

# Check if this is a cc command
if [[ ! "$PROMPT" =~ ^[[:space:]]*/cc: ]]; then
  log_info "Not a cc command, passing through"
  log_exit 0 "not a cc command"
  exit 0
fi

# Extract command name: /cc:command-name -> command-name
COMMAND=$(echo "$PROMPT" | sed -n 's|^[[:space:]]*/cc:\([a-z-]*\).*|\1|p')
ARGS=$(echo "$PROMPT" | sed -n 's|^[[:space:]]*/cc:[a-z-]*[[:space:]]*||p')
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

HANDLERS_DIR="$SCRIPT_DIR/handlers"

case "$COMMAND" in
  bump-version)
    log_info "Loading bump-version.sh"
    source "$HANDLERS_DIR/bump-version.sh"
    ;;
  sync-configs)
    log_info "Loading sync-configs.sh"
    source "$HANDLERS_DIR/sync-configs.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
