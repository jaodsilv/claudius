#!/bin/bash
# Main dispatcher for UserPromptSubmit hook
# Handles validation and setup for all /gitx:* commands
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
log_init "pre-command"

# Read JSON input from stdin
INPUT=$(cat)
log_section "Input Processing"
log_json "stdin_input" "$INPUT"

PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
log_debug "PROMPT" "$PROMPT"
log_debug "CWD" "$CWD"

# Check if this is a gitx command
if [[ ! "$PROMPT" =~ ^[[:space:]]*/gitx: ]]; then
  log_info "Not a gitx command, passing through"
  log_exit 0 "not a gitx command"
  exit 0
fi

# Extract command name: /gitx:command-name -> command-name
COMMAND=$(echo "$PROMPT" | sed -n 's|^[[:space:]]*/gitx:\([a-z-]*\).*|\1|p')
ARGS=$(echo "$PROMPT" | sed -n 's|^[[:space:]]*/gitx:[a-z-]*[[:space:]]*||p')
log_debug "COMMAND" "$COMMAND"
log_debug "ARGS" "$ARGS"

# Parse worktree from arguments or use CWD
# Supports: --worktree <path>, positional <path>, or default to CWD
WORKTREE="$CWD"
if [[ "$ARGS" =~ --worktree[[:space:]]+([^[:space:]]+) ]]; then
  WORKTREE="${BASH_REMATCH[1]}"
  log_debug "WORKTREE (from --worktree)" "$WORKTREE"
elif [[ -n "$ARGS" ]]; then
  # First positional argument might be a worktree path
  FIRST_ARG=$(echo "$ARGS" | awk '{print $1}')
  # Check if it looks like a path (starts with ., /, or drive letter)
  if [[ "$FIRST_ARG" =~ ^[./] ]] || [[ "$FIRST_ARG" =~ ^[A-Za-z]: ]]; then
    WORKTREE="$FIRST_ARG"
    log_debug "WORKTREE (from positional)" "$WORKTREE"
  fi
fi

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

WORKTREE=$(convert_path "$WORKTREE")
if [[ "$WORKTREE" == "." ]] || [[ -z "$WORKTREE" ]]; then
  WORKTREE=$(convert_path "$(pwd)")
fi

# Resolve relative paths to absolute (relative to CWD, not script dir)
if [[ ! "$WORKTREE" = /* ]]; then
  CWD_CONVERTED=$(convert_path "$CWD")
  WORKTREE=$(convert_path "$(cd "$CWD_CONVERTED" && cd "$WORKTREE" 2>/dev/null && pwd)")
fi
log_debug "WORKTREE (resolved)" "$WORKTREE"

# Common validation: git repo
log_section "Git Validation"
if ! git -C "$WORKTREE" rev-parse --git-dir &>/dev/null; then
  log_error "Not a git repository: $WORKTREE"
  log_exit 2 "not a git repository"
  echo "Error: '$WORKTREE' is not a git repository" >&2
  exit 2
fi
log_info "Git repository validated"

# Get current branch for context
CURRENT_BRANCH=$(git -C "$WORKTREE" branch --show-current 2>/dev/null || echo "")
log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

# Export variables for handler scripts
export WORKTREE
export ARGS
export METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"
export GITX_DEBUG
export GITX_LOG_VERBOSE
export GITX_LOG_DIR

log_debug "METADATA_FILE" "$METADATA_FILE"
log_debug "METADATA_EXISTS" "$(test -f "$METADATA_FILE" && echo "yes" || echo "no")"

# Dispatch to command-specific handler
log_section "Handler Dispatch"
log_info "Dispatching to handler: $COMMAND"

HANDLERS_DIR="$SCRIPT_DIR/handlers"

case "$COMMAND" in
  address-ci)
    log_info "Loading address-ci.sh"
    source "$HANDLERS_DIR/address-ci.sh"
    ;;
  address-review)
    log_info "Loading address-review.sh"
    source "$HANDLERS_DIR/address-review.sh"
    ;;
  comment-to-issue|fix-issue)
    log_info "Loading validate-issue.sh"
    source "$HANDLERS_DIR/validate-issue.sh"
    ;;
  comment-to-pr)
    log_info "Loading comment-to-pr.sh"
    source "$HANDLERS_DIR/comment-to-pr.sh"
    ;;
  ignore)
    log_info "Loading ignore.sh"
    source "$HANDLERS_DIR/ignore.sh"
    ;;
  merge-pr)
    log_info "Loading merge-pr.sh"
    source "$HANDLERS_DIR/merge-pr.sh"
    ;;
  merge)
    log_info "Loading merge.sh"
    source "$HANDLERS_DIR/merge.sh"
    ;;
  next-issue)
    log_info "Loading next-issue.sh"
    source "$HANDLERS_DIR/next-issue.sh"
    ;;
  next-turn)
    log_info "Loading next-turn.sh"
    source "$HANDLERS_DIR/next-turn.sh"
    ;;
  pr)
    log_info "Loading pr.sh"
    source "$HANDLERS_DIR/pr.sh"
    ;;
  update-pr)
    log_info "Loading update-pr.sh"
    source "$HANDLERS_DIR/update-pr.sh"
    ;;
  rebase)
    log_info "Loading rebase.sh"
    source "$HANDLERS_DIR/rebase.sh"
    ;;
  remove-branch)
    log_info "Loading remove-branch.sh"
    source "$HANDLERS_DIR/remove-branch.sh"
    ;;
  remove-worktree)
    log_info "Loading remove-worktree.sh"
    source "$HANDLERS_DIR/remove-worktree.sh"
    ;;
  review)
    log_info "Loading review.sh"
    source "$HANDLERS_DIR/review.sh"
    ;;
  refresh-metadata)
    log_info "Loading refresh-metadata.sh"
    source "$HANDLERS_DIR/refresh-metadata.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
