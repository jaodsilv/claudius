#!/bin/bash
# Handler for /gitx:address-review command
# Wait for CI, update turn, block if not AUTHOR (require --force to override)

# Source hook output library for cross-event-type output formatting
source "$SCRIPTS_DIR/lib/hook-output.sh"
source "$SCRIPTS_DIR/lib/args-validator.sh"

log_section "Address-Review Handler"
log_debug "ARGS" "$ARGS"

# Validate resolve-level if provided
RESOLVE_LEVEL=$(get_flag_value "$ARGS" "--resolve-level")
if [[ -n "$RESOLVE_LEVEL" ]]; then
  validate_one_of "resolve-level" "$RESOLVE_LEVEL" "all" "critical" "important"
fi

# Check for --force flag using helper
FORCE=false
if has_flag "$ARGS" "-f or --force"; then
  FORCE=true
fi
log_debug "FORCE" "$FORCE"

NO_METADATA_SYNC=false
if has_flag "$ARGS" "--no-metadata-sync"; then
  NO_METADATA_SYNC=true
fi
log_debug "NO_METADATA_SYNC" "$NO_METADATA_SYNC"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata found. Create a PR first with /gitx:pr" >&2
  exit 2
fi

if [[ "$NO_METADATA_SYNC" == "false" ]]; then
  # Wait for CI using centralized operation (suppress stdout, errors go to stderr)
  log_info "Waiting for CI to complete..."
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --wait-ci >/dev/null

  # Refresh metadata - this computes turn correctly using statusCheckRollup
  log_info "Refreshing metadata..."
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --refresh >/dev/null
else
  log_info "Skipping CI wait and metadata refresh (--no-metadata-sync)"
fi

# Check turn (unless --force)
TURN=$(yq -r '.turn' "$METADATA_FILE")
log_debug "TURN" "$TURN"

if [[ "$TURN" == "AUTHOR" ]] || [[ "$FORCE" == "true" ]]; then
  log_info "Proceeding with address-review (turn=$TURN, force=$FORCE)"
  log_exit 0 "proceed"
  hook_output_context "<worktree>$WORKTREE</worktree>
Turn: $TURN. Proceed with /gitx:address-review"
  exit 0
else
  log_warn "Turn is $TURN, not AUTHOR - blocking"
  log_exit 0 "wrong turn - block"
  hook_output_block "Current turn is $TURN, not AUTHOR. Cannot address review. Use --force to override."
  exit 0
fi
