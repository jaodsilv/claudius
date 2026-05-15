#!/bin/bash
# Bootstrap a CI worktree for foreign-PR review:
#   - validate gh auth
#   - fetch PR head and base with bounded depth
#   - check out refs/pr/<N>
#
# Idempotent: if HEAD already matches the PR head SHA, the checkout step is
# skipped. Safe to call multiple times.
#
# Usage:
#   bootstrap-pr-worktree.sh \
#     --repo <owner/name> \
#     --pr <number> \
#     --worktree <path> \
#     [--plugin-root <path>]
#
# Output (stdout): JSON with the cached PR view fields:
#   {
#     "headRefOid": "...",
#     "baseRefName": "...",
#     "baseRefOid": "...",
#     "state": "OPEN|CLOSED|MERGED",
#     "isDraft": true|false,
#     "title": "...",
#     "author": "...",
#     "labels": ["..."],
#     "commitsCount": <N>,
#     "changedFiles": <N>
#   }
#
# Errors are written to stderr and a non-zero exit code is returned. Callers
# should use the JSON only when exit code is 0.

set -uo pipefail

REPO=""
PR_NUMBER=""
WORKTREE=""
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)         REPO="$2"; shift 2 ;;
    --pr)           PR_NUMBER="$2"; shift 2 ;;
    --worktree)     WORKTREE="$2"; shift 2 ;;
    --plugin-root)  PLUGIN_ROOT="$2"; shift 2 ;;
    *)              shift ;;
  esac
done

if [[ -z "$REPO" || -z "$PR_NUMBER" || -z "$WORKTREE" ]]; then
  echo "bootstrap-pr-worktree.sh: --repo, --pr, --worktree are all required" >&2
  exit 2
fi

if [[ ! -d "$WORKTREE" ]]; then
  echo "bootstrap-pr-worktree.sh: worktree not found: $WORKTREE" >&2
  exit 2
fi

if [[ -z "$PLUGIN_ROOT" ]]; then
  PLUGIN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

RETRY_LIB="$PLUGIN_ROOT/scripts/lib/retry.sh"
if [[ -f "$RETRY_LIB" ]]; then
  # shellcheck disable=SC1090
  source "$RETRY_LIB"
fi

# --- Step 1: gh auth status ---
if ! gh auth status >/dev/null 2>&1; then
  echo "bootstrap-pr-worktree.sh: gh auth status failed (missing or expired token)" >&2
  exit 3
fi

# --- Step 2: gh pr view (cached) ---
gh_pr_view() {
  gh pr view -R "$REPO" "$PR_NUMBER" --json \
    headRefOid,baseRefName,baseRefOid,commits,state,isDraft,title,author,labels,changedFiles
}

if type -t retry_capture >/dev/null 2>&1; then
  pr_json=$(retry_capture "gh pr view" -- bash -c "$(declare -f gh_pr_view); gh_pr_view")
  rc=$?
else
  pr_json=$(gh_pr_view 2>/dev/null)
  rc=$?
fi

if [[ $rc -ne 0 || -z "$pr_json" ]]; then
  echo "bootstrap-pr-worktree.sh: gh pr view failed (rc=$rc)" >&2
  exit 4
fi

pr_json=$(printf '%s' "$pr_json" | tr -d '\r')

HEAD_REF_OID=$(printf '%s' "$pr_json" | jq -r '.headRefOid // ""')
BASE_REF_NAME=$(printf '%s' "$pr_json" | jq -r '.baseRefName // ""')
BASE_REF_OID=$(printf '%s' "$pr_json" | jq -r '.baseRefOid // ""')
COMMITS_COUNT=$(printf '%s' "$pr_json" | jq -r '.commits.totalCount // 0')

if [[ -z "$HEAD_REF_OID" ]]; then
  echo "bootstrap-pr-worktree.sh: could not determine headRefOid for PR $PR_NUMBER" >&2
  exit 4
fi

# --- Step 3: bounded depth ---
DEPTH=$((COMMITS_COUNT + 5))
[[ $DEPTH -lt 5 ]] && DEPTH=5

# --- Step 4: fetch PR head ref ---
git_fetch_head() {
  git -C "$WORKTREE" fetch origin "pull/$PR_NUMBER/head:refs/pr/$PR_NUMBER" --depth="$DEPTH" --no-tags
}

if type -t retry_cmd >/dev/null 2>&1; then
  retry_cmd "fetch pr head" -- bash -c "$(declare -f git_fetch_head); git_fetch_head" >/dev/null 2>&1
  rc=$?
else
  git_fetch_head >/dev/null 2>&1
  rc=$?
fi

if [[ $rc -ne 0 ]]; then
  echo "bootstrap-pr-worktree.sh: failed to fetch pull/$PR_NUMBER/head (rc=$rc)" >&2
  exit 5
fi

# --- Step 5: fetch base branch ---
if [[ -n "$BASE_REF_NAME" ]]; then
  git_fetch_base() {
    git -C "$WORKTREE" fetch origin "$BASE_REF_NAME" --depth="$DEPTH" --no-tags
  }

  if type -t retry_cmd >/dev/null 2>&1; then
    retry_cmd "fetch base" -- bash -c "$(declare -f git_fetch_base); git_fetch_base" >/dev/null 2>&1
    rc=$?
  else
    git_fetch_base >/dev/null 2>&1
    rc=$?
  fi

  if [[ $rc -ne 0 ]]; then
    echo "bootstrap-pr-worktree.sh: failed to fetch base $BASE_REF_NAME (rc=$rc, non-fatal)" >&2
    # non-fatal: head fetch is the critical one
  fi
fi

# --- Step 6: idempotent checkout ---
current_head=$(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null || echo "")
if [[ "$current_head" != "$HEAD_REF_OID" ]]; then
  if ! git -C "$WORKTREE" checkout --quiet --force "refs/pr/$PR_NUMBER" 2>/dev/null; then
    echo "bootstrap-pr-worktree.sh: failed to checkout refs/pr/$PR_NUMBER" >&2
    exit 6
  fi
fi

# Emit normalized PR metadata for the caller to consume
labels_json=$(printf '%s' "$pr_json" | jq -c '[.labels[]?.name // empty]')
author_login=$(printf '%s' "$pr_json" | jq -r '.author.login // ""')

jq -nc \
  --arg headRefOid "$HEAD_REF_OID" \
  --arg baseRefName "$BASE_REF_NAME" \
  --arg baseRefOid "$BASE_REF_OID" \
  --arg state "$(printf '%s' "$pr_json" | jq -r '.state // ""')" \
  --argjson isDraft "$(printf '%s' "$pr_json" | jq '.isDraft // false')" \
  --arg title "$(printf '%s' "$pr_json" | jq -r '.title // ""')" \
  --arg author "$author_login" \
  --argjson labels "$labels_json" \
  --argjson commitsCount "$COMMITS_COUNT" \
  --argjson changedFiles "$(printf '%s' "$pr_json" | jq '.changedFiles // 0')" \
  '{
    headRefOid: $headRefOid,
    baseRefName: $baseRefName,
    baseRefOid: $baseRefOid,
    state: $state,
    isDraft: $isDraft,
    title: $title,
    author: $author,
    labels: $labels,
    commitsCount: $commitsCount,
    changedFiles: $changedFiles
  }'

exit 0
