#!/bin/bash
# Handler for /review-loop:resume-loop skill
# Validates worktree and outputs it as additional context

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Resume-Loop Handler"

log_debug "WORKTREE" "$WORKTREE"

# Validate worktree exists
if [[ ! -d "$WORKTREE" ]]; then
  log_error "Worktree directory does not exist: $WORKTREE"
  log_exit 2 "worktree not found"
  hook_output_block "Worktree directory does not exist: $WORKTREE"
  exit 0
fi

log_info "Worktree validated: $WORKTREE"

# Read PR metadata if available
METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"
if [[ -f "$METADATA_FILE" ]]; then
  REVIEW_LOOP=$(yq -o json '.reviewLoop // {}' "$METADATA_FILE")
  TURN=$(yq -r '.turn // ""' "$METADATA_FILE")
  REVIEW_COUNT=$(yq -r '.reviewCount // 0' "$METADATA_FILE")
  APPROVED=$(yq -r '.approved // false' "$METADATA_FILE")

  log_info "Metadata loaded with reviewCount=$REVIEW_COUNT, turn=$TURN"
  log_exit 0 "proceed with metadata"

  hook_output_context "<worktree>$WORKTREE</worktree>
<pr-metadata>
<review-loop>
$REVIEW_LOOP
</review-loop>
<turn>$TURN</turn>
<review-count>$REVIEW_COUNT</review-count>
<approved>$APPROVED</approved>
</pr-metadata>"
else
  log_info "No metadata file found, passing worktree only"
  log_exit 0 "proceed without metadata"

  hook_output_context "<worktree>$WORKTREE</worktree>"
fi
exit 0
