#!/bin/bash
# Handler for /gitx:address-review command
# Wait for CI, update turn, block if not AUTHOR (require --force to override)

log_section "Address-Review Handler"

# Check for --force flag
FORCE=false
if [[ "$ARGS" =~ --force|-f ]]; then
  FORCE=true
fi
log_debug "FORCE" "$FORCE"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata found. Create a PR first with /gitx:pr" >&2
  exit 2
fi

# Wait for CI using centralized operation (suppress stdout, errors go to stderr)
log_info "Waiting for CI to complete..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" wait-ci "$WORKTREE" >/dev/null

# Refresh metadata - this computes turn correctly using statusCheckRollup
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE" >/dev/null

# Check turn (unless --force)
TURN=$(yq -r '.turn' "$METADATA_FILE")
log_debug "TURN" "$TURN"

if [[ "$TURN" == "AUTHOR" ]] || [[ "$FORCE" == "true" ]]; then
  log_info "Proceeding with address-review (turn=$TURN, force=$FORCE)"
  echo "Turn: $TURN. Proceed with /gitx:address-review"
  log_exit 0 "proceed"
  exit 0
else
  log_warn "Turn is $TURN, not AUTHOR - blocking"
  echo "Current turn is $TURN, not AUTHOR. Cannot address review." >&2
  echo "Use --force to override." >&2
  log_exit 2 "wrong turn"
  exit 2
fi
