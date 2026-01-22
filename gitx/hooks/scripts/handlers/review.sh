#!/bin/bash
# Handler for /gitx:review command
# Validate turn is REVIEW

log_section "Review Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata. Run /gitx:pr first." >&2
  exit 2
fi

TURN=$(yq -r '.turn // "unknown"' "$METADATA_FILE")
log_debug "TURN" "$TURN"

if [[ "$TURN" != "REVIEW" ]]; then
  log_error "Turn is $TURN, not REVIEW"
  log_exit 2 "wrong turn"
  echo "Error: Current turn is $TURN, not REVIEW. Cannot review." >&2
  exit 2
fi

log_info "Turn is REVIEW, proceeding"
echo "Turn is REVIEW. Proceeding with review."
log_exit 0 "proceed"
exit 0
