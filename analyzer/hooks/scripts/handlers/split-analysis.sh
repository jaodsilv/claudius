#!/bin/bash
# Handler for /analyzer:split-analysis command
# Validates analysis file exists and emits worktree context

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Split-Analysis Handler"

ANALYSIS_PATH=$(get_flag_value "$ARGS" "--analysis-path")
[[ -z "$ANALYSIS_PATH" ]] && ANALYSIS_PATH="$WORKTREE/.thoughts/analyzer/full-analysis.md"

log_debug "ANALYSIS_PATH" "$ANALYSIS_PATH"

if [[ ! -f "$ANALYSIS_PATH" ]]; then
  log_warn "Analysis file not found: $ANALYSIS_PATH"
  hook_output_block "Analysis file not found: $ANALYSIS_PATH. Run /analyzer:analyze first."
  exit 0
fi

log_info "Analysis file found, proceeding"
hook_output_context "<worktree>$WORKTREE</worktree>"
log_exit 0 "proceed"
exit 0
