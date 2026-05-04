#!/bin/bash
# Handler for /gitx:review command
# Supports --repo <owner/name> --pr <number> for foreign PR reviews
# Supports --ci-mode <job-name> to skip turn check when running in CI context

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Review Handler"

# --- Phase 0: Flag parsing & validation ---
REPO_FLAG=$(get_flag_value "$ARGS" "--repo")
PR_FLAG=$(get_flag_value "$ARGS" "--pr")
CI_MODE_FLAG=$(get_flag_value "$ARGS" "--ci-mode")
validate_requires "$ARGS" "--repo" "--pr"
validate_requires "$ARGS" "--pr" "--repo"

WT_FLAG_PRESENT=false
has_flag "$ARGS" "--worktree" && WT_FLAG_PRESENT=true

NO_METADATA_SYNC=false
if has_flag "$ARGS" "--no-metadata-sync"; then
  NO_METADATA_SYNC=true
fi
log_debug "NO_METADATA_SYNC" "$NO_METADATA_SYNC"

# --- Phase 1: Branch on flag presence ---
if [[ -n "$REPO_FLAG" ]]; then
  # Branch A: --repo + --pr provided, skip metadata/turn checks
  log_info "Branch A: --repo=$REPO_FLAG --pr=$PR_FLAG"
  REPO="$REPO_FLAG"
  PR_NUMBER="$PR_FLAG"
  LATEST_REVIEWED_COMMIT=""
  if [[ "$WT_FLAG_PRESENT" == "true" ]]; then
    WORKTREE_OUT="$WORKTREE"
  else
    WORKTREE_OUT=""
  fi
else
  # Branch B: no flags, use local metadata
  log_info "Branch B: using local metadata"

  if [[ ! -f "$METADATA_FILE" ]]; then
    if [[ "$NO_METADATA_SYNC" == "true" ]]; then
      log_error "No metadata and --no-metadata-sync set"
      log_exit 2 "no metadata - no-sync block"
      hook_output_block "No PR metadata. Run /gitx:pr first."
      exit 2
    fi
    log_info "Metadata not found, fetching..."
    if ! bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --refresh; then
      log_error "Failed to fetch metadata"
      log_exit 2 "fetch failed"
      hook_output_block "Failed to fetch PR metadata"
      exit 2
    fi
  fi

  if [[ ! -f "$METADATA_FILE" ]]; then
    log_error "No metadata after fetch"
    log_exit 2 "no metadata"
    hook_output_block "No PR metadata. Run /gitx:pr first."
    exit 2
  fi

  TURN=$(yq -r '.turn // "unknown"' "$METADATA_FILE")
  log_debug "TURN" "$TURN"

  if [[ -z "$CI_MODE_FLAG" && "$TURN" != "REVIEW" ]]; then
    log_error "Turn is $TURN, not REVIEW"
    log_exit 2 "wrong turn"
    hook_output_block "Current turn is $TURN, not REVIEW. Cannot review."
    exit 2
  fi

  log_info "Turn is $TURN, proceeding"

  PR_NUMBER=$(yq -r '.pr // ""' "$METADATA_FILE")
  LATEST_REVIEWED_COMMIT=$(yq -r '.latestReviewedCommit // ""' "$METADATA_FILE")

  remote_url=$(git -C "$WORKTREE" remote get-url origin 2>/dev/null || echo "")
  if [[ -z "$remote_url" ]]; then
    log_error "Could not determine remote URL"
    log_exit 2 "no remote"
    hook_output_block "Could not determine repository from git remote"
    exit 2
  fi
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    log_error "Could not parse repository from remote URL: $remote_url"
    log_exit 2 "bad remote"
    hook_output_block "Could not parse repository from remote URL"
    exit 2
  fi

  WORKTREE_OUT="$WORKTREE"
fi

# --- Phase 3: Emit additionalContext ---
OUT=""
[[ -n "$WORKTREE_OUT" ]] && OUT+="<worktree>$WORKTREE_OUT</worktree>"$'\n'
OUT+="<repo>$REPO</repo>"$'\n'
OUT+="<pr-number>$PR_NUMBER</pr-number>"$'\n'
[[ -n "$LATEST_REVIEWED_COMMIT" ]] && OUT+="<latest-reviewed-commit>$LATEST_REVIEWED_COMMIT</latest-reviewed-commit>"$'\n'
[[ -n "$CI_MODE_FLAG" ]] && OUT+="<ci-mode>$CI_MODE_FLAG</ci-mode>"$'\n'

log_info "Emitting additionalContext"
log_exit 0 "proceed"
hook_output_context "$OUT"
exit 0
