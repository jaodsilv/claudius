#!/bin/bash
# Handler for /gitx:review command
#
# Branch A: --repo + --pr provided. CI-ready path with worktree bootstrap,
#           marker-aware discovery of last reviewed commit, and skip-fast
#           guards. Used by the GitHub Actions workflow.
# Branch B: no --repo flag. Local turn-aware path that reads metadata.yaml.

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Review Handler"

# --- Phase 0: Flag parsing & validation ---
REPO_FLAG=$(get_flag_value "$ARGS" "--repo")
PR_FLAG=$(get_flag_value "$ARGS" "--pr")
CI_MODE_FLAG=$(get_flag_value "$ARGS" "--ci-mode")
MANUAL_LRC=$(get_flag_value "$ARGS" "--latest-reviewed-commit")
APPROVAL_LEVEL=$(get_flag_value "$ARGS" "--approval-level")
validate_requires "$ARGS" "--repo" "--pr"
validate_requires "$ARGS" "--pr" "--repo"
if [[ -n "$APPROVAL_LEVEL" ]]; then
  validate_one_of "approval-level" "$APPROVAL_LEVEL" "all" "critical" "important"
fi

WT_FLAG_PRESENT=false
has_flag "$ARGS" "--worktree" && WT_FLAG_PRESENT=true

NO_METADATA_SYNC=false
if has_flag "$ARGS" "--no-metadata-sync"; then
  NO_METADATA_SYNC=true
fi
log_debug "NO_METADATA_SYNC" "$NO_METADATA_SYNC"

INCLUDE_DRAFTS=false
has_flag "$ARGS" "--include-drafts" && INCLUDE_DRAFTS=true

FORCE_POST=false
has_flag "$ARGS" "--force-post" && FORCE_POST=true

# Bootstrap auto-trigger: CI env or explicit --bootstrap
DO_BOOTSTRAP=false
if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  DO_BOOTSTRAP=true
  log_debug "BOOTSTRAP" "auto (CI/GITHUB_ACTIONS)"
fi
if has_flag "$ARGS" "--bootstrap"; then
  DO_BOOTSTRAP=true
  log_debug "BOOTSTRAP" "explicit --bootstrap"
fi

# --- Phase 1: Branch on flag presence ---
if [[ -n "$REPO_FLAG" ]]; then
  # Branch A: --repo + --pr — CI-ready path
  log_info "Branch A: --repo=$REPO_FLAG --pr=$PR_FLAG bootstrap=$DO_BOOTSTRAP"
  REPO="$REPO_FLAG"
  PR_NUMBER="$PR_FLAG"

  # Defaults that may be overridden by bootstrap
  PR_VIEW_JSON=""
  HEAD_SHA=""
  BASE_REF_NAME=""
  BASE_SHA=""
  PR_STATE=""
  PR_IS_DRAFT="false"
  PR_TITLE=""
  PR_AUTHOR=""
  PR_LABELS_JSON="[]"
  CHANGED_FILES=0
  COMMITS_COUNT=0

  # --- Bootstrap (CI or --bootstrap) ---
  if [[ "$DO_BOOTSTRAP" == "true" ]]; then
    log_info "Bootstrapping worktree for PR $PR_NUMBER"
    PR_VIEW_JSON=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/reviews/bootstrap-pr-worktree.sh" \
      --repo "$REPO" \
      --pr "$PR_NUMBER" \
      --worktree "$WORKTREE" \
      --plugin-root "$CLAUDE_PLUGIN_ROOT" 2>&1)
    rc=$?
    if [[ $rc -ne 0 ]]; then
      log_error "Bootstrap failed (rc=$rc): $PR_VIEW_JSON"
      log_exit 2 "bootstrap failed"
      hook_output_block "Failed to bootstrap PR worktree (rc=$rc). Check gh authentication and network access."
      exit 0
    fi
  else
    # Local non-CI: still need PR metadata for skip-fast guards (best-effort)
    PR_VIEW_JSON=$(gh pr view -R "$REPO" "$PR_NUMBER" \
      --json headRefOid,baseRefName,baseRefOid,commits,state,isDraft,title,author,labels,changedFiles 2>/dev/null | tr -d '\r')
    if [[ -z "$PR_VIEW_JSON" ]]; then
      log_warn "gh pr view returned no data; skip-fast guards will be skipped"
    fi
  fi

  if [[ -n "$PR_VIEW_JSON" ]]; then
    # Use here-strings (<<<) instead of pipes to avoid pipefail interactions.
    # With `printf | jq`, a SIGPIPE or other quirk can cause the pipeline to
    # return non-zero even when jq emits the right value, which would either
    # double the output (with `|| echo default`) or wipe it (with `|| VAR=""`).
    HEAD_SHA=$(jq -r '.headRefOid // ""' 2>/dev/null <<< "$PR_VIEW_JSON")
    BASE_REF_NAME=$(jq -r '.baseRefName // ""' 2>/dev/null <<< "$PR_VIEW_JSON")
    BASE_SHA=$(jq -r '.baseRefOid // ""' 2>/dev/null <<< "$PR_VIEW_JSON")
    PR_STATE=$(jq -r '.state // ""' 2>/dev/null <<< "$PR_VIEW_JSON")
    PR_IS_DRAFT=$(jq -r '.isDraft // false' 2>/dev/null <<< "$PR_VIEW_JSON")
    [[ -z "$PR_IS_DRAFT" ]] && PR_IS_DRAFT="false"
    PR_TITLE=$(jq -r '.title // ""' 2>/dev/null <<< "$PR_VIEW_JSON")
    PR_AUTHOR=$(jq -r '.author.login // (.author | tostring? // "") // ""' 2>/dev/null <<< "$PR_VIEW_JSON")
    PR_LABELS_JSON=$(jq -c '[.labels[]?.name // empty]' 2>/dev/null <<< "$PR_VIEW_JSON")
    [[ -z "$PR_LABELS_JSON" ]] && PR_LABELS_JSON="[]"
    CHANGED_FILES=$(jq -r '.changedFiles // 0' 2>/dev/null <<< "$PR_VIEW_JSON")
    [[ -z "$CHANGED_FILES" ]] && CHANGED_FILES="0"
    COMMITS_COUNT=$(jq -r '.commits.totalCount // 0' 2>/dev/null <<< "$PR_VIEW_JSON")
    [[ -z "$COMMITS_COUNT" ]] && COMMITS_COUNT="0"
  fi

  # --- Discover latest reviewed commit (marker-aware) ---
  log_info "Discovering latest reviewed commit"
  DISCOVERY_ARGS=(--repo "$REPO" --pr "$PR_NUMBER" --worktree "$WORKTREE" --plugin-root "$CLAUDE_PLUGIN_ROOT")
  if [[ -n "$MANUAL_LRC" ]]; then
    DISCOVERY_ARGS+=(--latest-reviewed-commit "$MANUAL_LRC")
  fi
  DISCOVERY_JSON=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/reviews/discover-latest-reviewed.sh" "${DISCOVERY_ARGS[@]}" 2>/dev/null)
  if [[ -z "$DISCOVERY_JSON" ]]; then
    DISCOVERY_JSON='{"head_sha":"","latest_reviewed_commit":"","source":"none","round":0}'
  fi
  log_debug "DISCOVERY_JSON" "$DISCOVERY_JSON"

  LATEST_REVIEWED_COMMIT=$(echo "$DISCOVERY_JSON" | jq -r '.latest_reviewed_commit // ""')
  LATEST_REVIEWED_SOURCE=$(echo "$DISCOVERY_JSON" | jq -r '.source // "none"')
  DISC_HEAD_SHA=$(echo "$DISCOVERY_JSON" | jq -r '.head_sha // ""')
  DISC_ROUND=$(echo "$DISCOVERY_JSON" | jq -r '.round // 0')

  # --- Skip-fast guards ---
  # 1. Closed/merged
  if [[ "$PR_STATE" == "CLOSED" || "$PR_STATE" == "MERGED" ]]; then
    log_info "PR is $PR_STATE, skipping"
    log_exit 0 "pr $PR_STATE"
    hook_output_block "PR $REPO#$PR_NUMBER is $PR_STATE, nothing to review."
    exit 0
  fi

  # 2. Draft
  if [[ "$PR_IS_DRAFT" == "true" && "$INCLUDE_DRAFTS" != "true" ]]; then
    log_info "PR is draft, skipping (use --include-drafts to override)"
    log_exit 0 "pr draft"
    hook_output_block "PR $REPO#$PR_NUMBER is a draft, skipping (use --include-drafts to override)."
    exit 0
  fi

  # 3. No new commits since last review — only when we can verify both endpoints
  #    locally. Skip the check for manual overrides (SHA may be a fake/foreign
  #    SHA not in the local repo) or when the LRC isn't resolvable in the
  #    current worktree (foreign PRs without bootstrap).
  if [[ -n "$LATEST_REVIEWED_COMMIT" && -n "$HEAD_SHA" \
        && "$LATEST_REVIEWED_COMMIT" != "$HEAD_SHA" \
        && "$LATEST_REVIEWED_SOURCE" != "manual" ]] \
     && git -C "$WORKTREE" rev-parse --quiet --verify "$LATEST_REVIEWED_COMMIT^{commit}" >/dev/null 2>&1 \
     && git -C "$WORKTREE" rev-parse --quiet --verify "$HEAD_SHA^{commit}" >/dev/null 2>&1; then
    new_commit_count=$(git -C "$WORKTREE" log "$LATEST_REVIEWED_COMMIT..$HEAD_SHA" --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [[ -n "$new_commit_count" && "$new_commit_count" == "0" ]]; then
      log_info "No new commits since $LATEST_REVIEWED_COMMIT, skipping"
      log_exit 0 "no new commits"
      hook_output_block "No new commits since last review ($LATEST_REVIEWED_COMMIT), skipping."
      exit 0
    fi
  elif [[ -n "$DISC_HEAD_SHA" && -n "$HEAD_SHA" && "$DISC_HEAD_SHA" == "$HEAD_SHA" && "$FORCE_POST" != "true" && "$LATEST_REVIEWED_SOURCE" != "none" && "$LATEST_REVIEWED_SOURCE" != "manual" ]]; then
    # Marker exists for current head — idempotent skip unless --force-post
    log_info "Marker matches current head $HEAD_SHA, skipping (use --force-post to override)"
    log_exit 0 "marker matches head"
    hook_output_block "PR $REPO#$PR_NUMBER already reviewed at $HEAD_SHA (round $DISC_ROUND, source=$LATEST_REVIEWED_SOURCE). Use --force-post to re-review."
    exit 0
  fi

  # 4. Bot self-review (last commit author equals current gh user)
  if [[ -n "$HEAD_SHA" ]]; then
    bot_login=$(gh api user --jq '.login' 2>/dev/null || echo "")
    if [[ -n "$bot_login" ]]; then
      last_commit_author=$(git -C "$WORKTREE" log -1 --format='%an' "$HEAD_SHA" 2>/dev/null || echo "")
      last_commit_email=$(git -C "$WORKTREE" log -1 --format='%ae' "$HEAD_SHA" 2>/dev/null || echo "")
      if [[ "$last_commit_author" == "$bot_login" || "$last_commit_email" == *"$bot_login"* ]]; then
        log_info "Last commit by bot $bot_login, skipping self-review"
        log_exit 0 "bot self-review"
        hook_output_block "Last commit on $REPO#$PR_NUMBER is by $bot_login (current gh user); skipping self-review."
        exit 0
      fi
    fi
  fi

  # Worktree output: emit when bootstrap occurred (we own it) or --worktree explicit
  if [[ "$DO_BOOTSTRAP" == "true" || "$WT_FLAG_PRESENT" == "true" ]]; then
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
  LATEST_REVIEWED_SOURCE=""
  HEAD_SHA=""
  BASE_REF_NAME=""
  BASE_SHA=""
  PR_STATE=""
  PR_IS_DRAFT=""
  PR_TITLE=""
  PR_AUTHOR=""
  PR_LABELS_JSON=""
  CHANGED_FILES=""

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
[[ -n "${LATEST_REVIEWED_SOURCE:-}" ]] && OUT+="<latest-reviewed-source>$LATEST_REVIEWED_SOURCE</latest-reviewed-source>"$'\n'
[[ -n "$CI_MODE_FLAG" ]] && OUT+="<ci-mode>$CI_MODE_FLAG</ci-mode>"$'\n'
[[ -n "${HEAD_SHA:-}" ]] && OUT+="<head-sha>$HEAD_SHA</head-sha>"$'\n'
[[ -n "${BASE_REF_NAME:-}" ]] && OUT+="<base-branch>$BASE_REF_NAME</base-branch>"$'\n'
[[ -n "${BASE_SHA:-}" ]] && OUT+="<base-sha>$BASE_SHA</base-sha>"$'\n'
[[ -n "${PR_TITLE:-}" ]] && OUT+="<pr-title>$PR_TITLE</pr-title>"$'\n'
[[ -n "${PR_AUTHOR:-}" ]] && OUT+="<pr-author>$PR_AUTHOR</pr-author>"$'\n'
[[ -n "${PR_LABELS_JSON:-}" && "${PR_LABELS_JSON:-}" != "[]" ]] && OUT+="<pr-labels>$PR_LABELS_JSON</pr-labels>"$'\n'
[[ -n "${PR_IS_DRAFT:-}" ]] && OUT+="<pr-draft>$PR_IS_DRAFT</pr-draft>"$'\n'
[[ -n "${PR_STATE:-}" ]] && OUT+="<pr-state>$PR_STATE</pr-state>"$'\n'
[[ -n "${CHANGED_FILES:-}" && "${CHANGED_FILES:-0}" != "0" ]] && OUT+="<changed-files-count>$CHANGED_FILES</changed-files-count>"$'\n'
[[ "${FORCE_POST:-false}" == "true" ]] && OUT+="<force-post>true</force-post>"$'\n'
[[ -n "${APPROVAL_LEVEL:-}" ]] && OUT+="<approval-level>$APPROVAL_LEVEL</approval-level>"$'\n'

log_info "Emitting additionalContext"
log_exit 0 "proceed"
hook_output_context "$OUT"
exit 0
