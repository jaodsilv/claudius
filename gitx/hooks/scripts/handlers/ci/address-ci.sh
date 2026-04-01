#!/bin/bash
# Handler for /gitx:address-ci command
# Wait for CI, refresh metadata (which computes turn correctly), block if not CI-REVIEW

# Source hook output library for cross-event-type output formatting
source "$SCRIPTS_DIR/lib/hook-output.sh"

log_section "Address-CI Handler"

if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata found. Create a PR first with /gitx:pr" >&2
  exit 2
fi

# Loop until turn resolves to something other than CI-PENDING
MAX_WAIT=1740   # stay under hook timeout (1800s) with buffer
ELAPSED=0

while true; do
  # Refresh metadata - this computes turn correctly using statusCheckRollup
  # which properly handles skipped jobs (unlike gh run list)
  log_info "Refreshing metadata..."
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --refresh >/dev/null

  TURN=$(yq -r '.turn' "$METADATA_FILE")
  log_debug "TURN" "$TURN"

  case "$TURN" in
    CI-REVIEW)
      # Count failing checks from metadata for context message
      FAILED=$(yq -r '[.ciStatus[] | select(.conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "CANCELLED" and .conclusion != "NEUTRAL" and .conclusion != null and .conclusion != "")] | length' "$METADATA_FILE")
      log_info "CI has $FAILED failed checks"
      log_exit 0 "CI failures to address"
      hook_output_context "CI Status: $FAILED failed checks. Proceed with /gitx:address-ci"
      exit 0
      ;;
    REVIEW|AUTHOR)
      log_info "Turn is $TURN - cannot address CI"
      log_exit 0 "wrong turn - block"
      hook_output_block "Turn is $TURN. Cannot address CI."
      exit 0
      ;;
    CI-PENDING)
      if [[ $ELAPSED -ge $MAX_WAIT ]]; then
        log_info "CI still pending after ${ELAPSED}s - giving up"
        log_exit 0 "CI pending timeout - block"
        hook_output_block "CI still pending after ${ELAPSED}s. Try again later."
        exit 0
      fi
      # Wait random 10-60 seconds before retrying
      WAIT=$(( (RANDOM % 51) + 10 ))
      log_info "CI pending, waiting ${WAIT}s (${ELAPSED}s elapsed)..."
      sleep $WAIT
      ELAPSED=$((ELAPSED + WAIT))
      ;;
    *)
      # Unknown turn state - let it through with warning
      log_info "Unexpected turn: $TURN - allowing execution"
      log_exit 0 "unexpected turn - allow"
      hook_output_context "Unexpected turn state: $TURN. Proceeding with /gitx:address-ci"
      exit 0
      ;;
  esac
done
