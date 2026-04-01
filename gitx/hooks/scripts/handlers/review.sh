#!/bin/bash
# Handler for /gitx:review command
# Ensures metadata, validates turn, and builds review prompt

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Review Handler"

# --- Phase 1: Ensure metadata exists ---
if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "Metadata not found, fetching..."
  FETCH_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/metadata/fetch-pr-metadata.sh"
  if ! bash "$FETCH_SCRIPT" "$WORKTREE"; then
    log_error "Failed to fetch metadata"
    log_exit 2 "fetch failed"
    hook_output_block "Failed to fetch PR metadata"
    exit 2
  fi
fi

# Re-check after potential fetch
if [[ ! -f "$METADATA_FILE" ]]; then
  log_error "No metadata after fetch"
  log_exit 2 "no metadata"
  hook_output_block "No PR metadata. Run /gitx:pr first."
  exit 2
fi

# --- Phase 2: Validate turn ---
TURN=$(yq -r '.turn // "unknown"' "$METADATA_FILE")
log_debug "TURN" "$TURN"

if [[ "$TURN" != "REVIEW" ]]; then
  log_error "Turn is $TURN, not REVIEW"
  log_exit 2 "wrong turn"
  hook_output_block "Current turn is $TURN, not REVIEW. Cannot review."
  exit 2
fi

log_info "Turn is REVIEW, proceeding"

# --- Phase 3: Build review prompt ---
log_info "Building review prompt..."
BUILD_SCRIPT="${HANDLERS_DIR}/build-review-prompt.sh"
if ! bash "$BUILD_SCRIPT" "$WORKTREE"; then
  log_error "Failed to build review prompt"
  log_exit 2 "build prompt failed"
  hook_output_block "Failed to build review prompt"
  exit 2
fi

# --- Phase 4: Output for skill ---
PROMPT_FILE="$WORKTREE/.thoughts/pr/review-prompt.txt"
log_info "Setup complete, prompt at $PROMPT_FILE"
log_exit 0 "proceed"

# Read prompt content and output as additional context
REVIEW_CONTENT=$(inject_or_read "$PROMPT_FILE" "review-prompt")
hook_output_context "<worktree>$WORKTREE</worktree>
$REVIEW_CONTENT"
exit 0
