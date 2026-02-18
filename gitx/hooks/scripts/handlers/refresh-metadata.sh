#!/bin/bash
# Handler for /gitx:refresh-metadata command
# Refresh PR metadata, block always (no LLM needed)

# Source args validator and hook output
source "$SCRIPTS_DIR/lib/args-validator.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"

log_section "Refresh-Metadata Handler"
log_debug "ARGS" "$ARGS"

# Parse flags using library functions
REFRESH_ALL=false
if has_flag "$ARGS" "--all"; then
  REFRESH_ALL=true
fi

FIELDS=$(get_flag_value "$ARGS" "--fields")

# Default to --all if no flags specified
if [[ "$REFRESH_ALL" == "false" ]] && [[ -z "$FIELDS" ]]; then
  REFRESH_ALL=true
fi

log_debug "REFRESH_ALL" "$REFRESH_ALL"
log_debug "FIELDS" "$FIELDS"

# Use CURRENT_BRANCH from parent (exported by init())
log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

if ! gh pr view "$CURRENT_BRANCH" &>/dev/null; then
  log_error "No PR found for branch '$CURRENT_BRANCH'"
  log_exit 2 "no PR"
  echo "Error: No PR found for branch '$CURRENT_BRANCH'" >&2
  exit 2
fi

FETCH_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/scripts/handlers/fetch-pr-metadata.sh"

if [[ "$REFRESH_ALL" == "true" ]]; then
  # Full refresh - re-fetch (atomic write preserves existing file on failure)
  log_info "Performing full metadata refresh..."
  rm -rf "$WORKTREE/.thoughts/pr/ci"

  # Capture fetch output (suppress from stdout, we'll include in block reason)
  if FETCH_OUTPUT=$(bash "$FETCH_SCRIPT" "$WORKTREE" ); then
    # Extract the message from fetch output if it's JSON
    FETCH_MESSAGE=$(echo "$FETCH_OUTPUT" | rg -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"message"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/' | tail -1)
    if [[ -z "$FETCH_MESSAGE" ]]; then
      FETCH_MESSAGE="$METADATA_FILE"
    fi
    log_info "Metadata refreshed successfully"
    log_exit 0 "block with JSON"
    hook_output_block "Metadata refreshed successfully. Written to $FETCH_MESSAGE"
    exit 0
  else
    log_error "Failed to refresh metadata"
    echo "Error: Failed to refresh metadata" >&2
    exit 2
  fi
else
  # Selective refresh based on --fields
  log_info "Performing selective refresh for fields: $FIELDS"

  # Always do a full refresh for now (selective refresh would require
  # significant refactoring of fetch-pr-metadata.sh into modular functions)
  # Capture fetch output (suppress from stdout, we'll include in block reason)
  if FETCH_OUTPUT=$(bash "$FETCH_SCRIPT" "$WORKTREE" ); then
    FETCH_MESSAGE=$(echo "$FETCH_OUTPUT" | rg -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"message"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/' | tail -1)
    if [[ -z "$FETCH_MESSAGE" ]]; then
      FETCH_MESSAGE="$METADATA_FILE"
    fi
    log_info "Metadata refreshed for fields: $FIELDS"
    log_exit 0 "block with JSON"
    hook_output_block "Metadata refreshed for fields: $FIELDS. Written to $FETCH_MESSAGE"
    exit 0
  else
    log_error "Failed to refresh metadata"
    echo "Error: Failed to refresh metadata" >&2
    exit 2
  fi
fi
