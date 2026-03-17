#!/bin/bash
# Handler for /analyzer:merge-analyses command
# Validates analysis paths are provided and emits worktree context

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Merge-Analyses Handler"

ANALYSIS_PATHS=$(get_flag_value "$ARGS" "--analysis-paths" --greedy)
log_debug "ANALYSIS_PATHS" "$ANALYSIS_PATHS"

if [[ -z "$ANALYSIS_PATHS" ]]; then
  log_warn "No analysis paths provided"
  hook_output_block "At least 2 analysis file paths required. Use --analysis-paths <path1> <path2> ..."
  exit 0
fi

# Count paths
read -ra PATH_ARRAY <<< "$ANALYSIS_PATHS"
if [[ ${#PATH_ARRAY[@]} -lt 2 ]]; then
  log_warn "Only ${#PATH_ARRAY[@]} path(s) provided, need at least 2"
  hook_output_block "At least 2 analysis file paths required. Got ${#PATH_ARRAY[@]}."
  exit 0
fi

log_info "${#PATH_ARRAY[@]} analysis paths provided, proceeding"
hook_output_context "<worktree>$WORKTREE</worktree>"
log_exit 0 "proceed"
exit 0
