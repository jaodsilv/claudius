#!/bin/bash
# Handler for /gitx:address-ci command
# Supports --repo <owner/name> --pr <number> for foreign PR mode (flag plumbing only)
# Supports --ci-mode <job-name> to skip waiting for the named job (running in CI context)

source "$SCRIPTS_DIR/lib/hook-output.sh"

log_section "Address-CI Handler"

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

  OUT=""
  [[ "$WT_FLAG_PRESENT" == "true" ]] && OUT+="<worktree>$WORKTREE</worktree>"$'\n'
  OUT+="<repo>$REPO_FLAG</repo>"$'\n'
  OUT+="<pr-number>$PR_FLAG</pr-number>"$'\n'
  [[ -n "$CI_MODE_FLAG" ]] && OUT+="<ci-mode>$CI_MODE_FLAG</ci-mode>"$'\n'

  log_exit 0 "foreign PR mode"
  hook_output_context "$OUT"
  exit 0
fi

# Branch B: no --repo/--pr flags, use local metadata
log_info "Branch B: using local metadata"

if [[ ! -f "$METADATA_FILE" ]]; then
  if [[ -n "$CI_MODE_FLAG" ]]; then
    log_info "CI mode: no metadata file, emitting minimal context"
    log_exit 0 "ci-mode no metadata"
    hook_output_context "<ci-mode>$CI_MODE_FLAG</ci-mode>"
    exit 0
  fi
  log_error "No metadata file found"
  log_exit 2 "no metadata"
  echo "No PR metadata found. Create a PR first with /gitx:pr" >&2
  exit 2
fi

# CI mode: poll until all other jobs finish (excluding the named job), never block
if [[ -n "$CI_MODE_FLAG" ]]; then
  log_info "CI mode: job=$CI_MODE_FLAG, waiting for other jobs to finish"
  MAX_WAIT=1740
  ELAPSED=0

  _ci_mode_emit() {
    local failed
    failed=$(yq -r --arg job "$CI_MODE_FLAG" \
      '[.ciStatus[] | select(.name != $job and .conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "CANCELLED" and .conclusion != "NEUTRAL" and .conclusion != null and .conclusion != "")] | length' \
      "$METADATA_FILE")
    log_info "CI mode: emitting context, $failed failed checks (excluding $CI_MODE_FLAG)"
    hook_output_context "<worktree>$WORKTREE</worktree>
<ci-failed-count>$failed</ci-failed-count>
<ci-mode>$CI_MODE_FLAG</ci-mode>"
  }

  if [[ "$NO_METADATA_SYNC" == "true" ]]; then
    log_info "CI mode: --no-metadata-sync, skipping wait loop and emitting from current metadata"
    log_exit 0 "ci-mode no-sync emit"
    _ci_mode_emit
    exit 0
  fi

  while true; do
    log_info "CI mode: refreshing metadata..."
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --refresh >/dev/null

    OTHER_PENDING=$(yq -r --arg job "$CI_MODE_FLAG" \
      '[.ciStatus[] | select(.name != $job and (.conclusion == null or .conclusion == ""))] | length' \
      "$METADATA_FILE")
    log_debug "OTHER_PENDING" "$OTHER_PENDING"

    if [[ "$OTHER_PENDING" -eq 0 ]]; then
      log_exit 0 "ci-mode all other jobs done"
      _ci_mode_emit
      exit 0
    fi

    if [[ $ELAPSED -ge $MAX_WAIT ]]; then
      log_info "CI mode: $OTHER_PENDING other jobs still pending after ${ELAPSED}s, proceeding"
      log_exit 0 "ci-mode timeout proceed"
      _ci_mode_emit
      exit 0
    fi

    WAIT=$(( (RANDOM % 51) + 10 ))
    log_info "CI mode: $OTHER_PENDING other jobs pending, waiting ${WAIT}s (${ELAPSED}s elapsed)..."
    sleep $WAIT
    ELAPSED=$((ELAPSED + WAIT))
  done
fi

# --no-metadata-sync: skip the wait loop, read existing turn once and dispatch
if [[ "$NO_METADATA_SYNC" == "true" ]]; then
  TURN=$(yq -r '.turn' "$METADATA_FILE")
  log_debug "TURN" "$TURN"
  log_info "--no-metadata-sync: dispatching on stale turn=$TURN"
  case "$TURN" in
    CI-REVIEW)
      FAILED=$(yq -r '[.ciStatus[] | select(.conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "CANCELLED" and .conclusion != "NEUTRAL" and .conclusion != null and .conclusion != "")] | length' "$METADATA_FILE")
      log_info "CI has $FAILED failed checks (stale)"
      log_exit 0 "CI failures to address (no-sync)"
      hook_output_context "<worktree>$WORKTREE</worktree>
<ci-failed-count>$FAILED</ci-failed-count>"
      exit 0
      ;;
    *)
      log_info "Stale metadata: turn=$TURN - blocking"
      log_exit 0 "stale metadata - block"
      hook_output_block "Stale metadata (--no-metadata-sync). Turn=$TURN."
      exit 0
      ;;
  esac
fi

# Loop until turn resolves to something other than CI-PENDING
MAX_WAIT=1740   # stay under hook timeout (1800s) with buffer
ELAPSED=0

while true; do
  log_info "Refreshing metadata..."
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" --worktree "$WORKTREE" --refresh >/dev/null

  TURN=$(yq -r '.turn' "$METADATA_FILE")
  log_debug "TURN" "$TURN"

  case "$TURN" in
    CI-REVIEW)
      FAILED=$(yq -r '[.ciStatus[] | select(.conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "CANCELLED" and .conclusion != "NEUTRAL" and .conclusion != null and .conclusion != "")] | length' "$METADATA_FILE")
      log_info "CI has $FAILED failed checks"
      log_exit 0 "CI failures to address"
      hook_output_context "<worktree>$WORKTREE</worktree>
<ci-failed-count>$FAILED</ci-failed-count>"
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
      WAIT=$(( (RANDOM % 51) + 10 ))
      log_info "CI pending, waiting ${WAIT}s (${ELAPSED}s elapsed)..."
      sleep $WAIT
      ELAPSED=$((ELAPSED + WAIT))
      ;;
    *)
      log_info "Unexpected turn: $TURN - allowing execution"
      log_exit 0 "unexpected turn - allow"
      hook_output_context "Unexpected turn state: $TURN. Proceeding with /gitx:address-ci"
      exit 0
      ;;
  esac
done
