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

BRANCH=$(yq -r '.branch' "$METADATA_FILE")
log_debug "BRANCH" "$BRANCH"

# Wait for CI
log_info "Waiting for CI to complete..."
MAX_WAIT=600
ELAPSED=0
while [[ $ELAPSED -lt $MAX_WAIT ]]; do
  PENDING=$(gh run list -b "$BRANCH" --json status --jq '[.[] | select(.status != "completed")] | length' || echo "0")
  log_debug "PENDING_CHECKS" "$PENDING"
  if [[ "$PENDING" == "0" ]]; then
    log_info "All CI checks completed"
    break
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

# Refresh metadata
log_info "Refreshing metadata..."
bash "${CLAUDE_PLUGIN_ROOT}/skills/managing-pr-metadata/scripts/metadata-operations.sh" fetch "$WORKTREE"

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
