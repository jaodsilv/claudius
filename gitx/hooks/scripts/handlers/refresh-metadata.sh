#!/bin/bash
# Handler for /gitx:refresh-metadata command
# Refresh PR metadata, block always (no LLM needed)

log_section "Refresh-Metadata Handler"
log_debug "ARGS" "$ARGS"

# Parse flags
REFRESH_ALL=false
FIELDS=""

if [[ "$ARGS" =~ --all ]]; then
  REFRESH_ALL=true
fi

if [[ "$ARGS" =~ --fields[[:space:]]+([^[:space:]]+) ]]; then
  FIELDS="${BASH_REMATCH[1]}"
fi

# Default to --all if no flags specified
if [[ "$REFRESH_ALL" == "false" ]] && [[ -z "$FIELDS" ]]; then
  REFRESH_ALL=true
fi

log_debug "REFRESH_ALL" "$REFRESH_ALL"
log_debug "FIELDS" "$FIELDS"

# Validate PR exists for current branch
CURRENT_BRANCH=$(git -C "$WORKTREE" branch --show-current)
log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

if ! gh pr view "$CURRENT_BRANCH" &>/dev/null; then
  log_error "No PR found for branch '$CURRENT_BRANCH'"
  log_exit 2 "no PR"
  echo "Error: No PR found for branch '$CURRENT_BRANCH'" >&2
  exit 2
fi

FETCH_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/scripts/fetch-pr-metadata.sh"

if [[ "$REFRESH_ALL" == "true" ]]; then
  # Full refresh - delete and re-fetch
  log_info "Performing full metadata refresh..."
  rm -f "$METADATA_FILE"
  rm -rf "$WORKTREE/.thoughts/pr/ci"

  if bash "$FETCH_SCRIPT" "$WORKTREE"; then
    log_info "Metadata refreshed successfully"
    echo "Metadata refreshed successfully."
  else
    log_error "Failed to refresh metadata"
    echo "Error: Failed to refresh metadata" >&2
  fi
else
  # Selective refresh based on --fields
  log_info "Performing selective refresh for fields: $FIELDS"

  # Always do a full refresh for now (selective refresh would require
  # significant refactoring of fetch-pr-metadata.sh into modular functions)
  if bash "$FETCH_SCRIPT" "$WORKTREE"; then
    log_info "Metadata refreshed for fields: $FIELDS"
    echo "Metadata refreshed for fields: $FIELDS"
  else
    log_error "Failed to refresh metadata"
    echo "Error: Failed to refresh metadata" >&2
  fi
fi

log_exit 2 "block always"
exit 2  # Block always - hook handles everything
