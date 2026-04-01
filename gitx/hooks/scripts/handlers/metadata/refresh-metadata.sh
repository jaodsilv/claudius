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

METADATA_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh"

if [[ "$REFRESH_ALL" == "true" ]]; then
  log_info "Performing full metadata refresh..."
  rm -rf "$WORKTREE/.thoughts/pr/ci"

  if FETCH_OUTPUT=$(bash "$METADATA_SCRIPT" --worktree "$WORKTREE" --refresh 2>&1); then
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
  log_info "Performing selective refresh for fields: $FIELDS"

  if FETCH_OUTPUT=$(bash "$METADATA_SCRIPT" --worktree "$WORKTREE" --refresh 2>&1); then
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
