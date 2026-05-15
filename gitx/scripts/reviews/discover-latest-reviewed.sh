#!/bin/bash
# Discover the latest reviewed commit for a PR by scanning multiple GitHub
# surfaces for a marker line, falling back to the legacy reviews-only heuristic.
#
# Marker format (single-line HTML comment):
#   <!-- claudius-review:v=1:head_sha=<40-hex>:base_sha=<40-hex>:round=<N>:posted_at=<ISO8601> -->
#
# Surfaces scanned (ordered by preference, latest timestamp wins):
#   1. reviews         — formal PR reviews
#   2. comments        — top-level PR conversation comments
#   3. reviewThreads   — replies inside review threads
#
# Output: a single JSON object on stdout:
#   {
#     "head_sha": "<sha or empty>",
#     "latest_reviewed_commit": "<sha or empty>",
#     "source": "reviews|comments|threads|none|manual",
#     "round": <N>
#   }
#
# Usage:
#   discover-latest-reviewed.sh \
#     --repo <owner/name> \
#     --pr <number> \
#     [--worktree <path>] \
#     [--latest-reviewed-commit <sha>] \
#     [--plugin-root <path>]
#
# Notes:
#   - --latest-reviewed-commit always wins; result.source = "manual".
#   - Without a worktree, latest_reviewed_commit falls back to head_sha (no
#     local repo to resolve `head_sha^`).
#   - Falls back gracefully when gh/jq fail; emits source="none" with empty
#     fields rather than erroring out, so the caller can decide.

set -uo pipefail

# --- Arg parsing ---
REPO=""
PR_NUMBER=""
WORKTREE=""
MANUAL_SHA=""
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)                    REPO="$2"; shift 2 ;;
    --pr)                      PR_NUMBER="$2"; shift 2 ;;
    --worktree)                WORKTREE="$2"; shift 2 ;;
    --latest-reviewed-commit)  MANUAL_SHA="$2"; shift 2 ;;
    --plugin-root)             PLUGIN_ROOT="$2"; shift 2 ;;
    *)                         shift ;;
  esac
done

if [[ -z "$PLUGIN_ROOT" ]]; then
  PLUGIN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

# Source retry helpers if available (graceful no-op otherwise)
RETRY_LIB="$PLUGIN_ROOT/scripts/lib/retry.sh"
if [[ -f "$RETRY_LIB" ]]; then
  # shellcheck disable=SC1090
  source "$RETRY_LIB"
fi

_emit_result() {
  local head_sha="$1"
  local lrc="$2"
  local source="$3"
  local round="${4:-0}"
  jq -nc \
    --arg head_sha "$head_sha" \
    --arg lrc "$lrc" \
    --arg source "$source" \
    --argjson round "$round" \
    '{head_sha: $head_sha, latest_reviewed_commit: $lrc, source: $source, round: $round}'
}

# --- Manual override short-circuits everything ---
if [[ -n "$MANUAL_SHA" ]]; then
  _emit_result "" "$MANUAL_SHA" "manual" 0
  exit 0
fi

if [[ -z "$REPO" || -z "$PR_NUMBER" ]]; then
  echo "discover-latest-reviewed.sh: --repo and --pr are required (or use --latest-reviewed-commit)" >&2
  _emit_result "" "" "none" 0
  exit 0
fi

REPO_OWNER="${REPO%%/*}"
REPO_NAME="${REPO#*/}"

# --- GraphQL: fetch reviews + comments + reviewThreads + headRefOid ---
graphql_query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      headRefOid
      reviews(last: 100) {
        nodes {
          id
          body
          submittedAt
          isMinimized
          commit { oid }
        }
      }
      comments(last: 100) {
        nodes {
          id
          body
          createdAt
        }
      }
      reviewThreads(last: 100) {
        nodes {
          comments(last: 100) {
            nodes {
              id
              body
              createdAt
            }
          }
        }
      }
    }
  }
}'

# Run the GraphQL query (with retry if helper is available)
gh_api_call() {
  gh api graphql \
    -f query="$graphql_query" \
    -f owner="$REPO_OWNER" \
    -f repo="$REPO_NAME" \
    -F number="$PR_NUMBER"
}

if type -t retry_capture >/dev/null 2>&1; then
  raw=$(retry_capture "discover graphql" -- bash -c "$(declare -f gh_api_call); gh_api_call")
  rc=$?
else
  raw=$(gh_api_call 2>/dev/null)
  rc=$?
fi

if [[ $rc -ne 0 || -z "$raw" ]]; then
  _emit_result "" "" "none" 0
  exit 0
fi

raw=$(printf '%s' "$raw" | tr -d '\r')

# Extract HEAD ref oid (used as fallback for empty worktree case)
HEAD_REF_OID=$(printf '%s' "$raw" | jq -r '.data.repository.pullRequest.headRefOid // ""' 2>/dev/null)

# Marker regex (BRE-friendly; ERE used via grep -E in jq filter):
#   <!-- claudius-review:v=1:head_sha=<40hex>:base_sha=<40hex>:round=<N>:posted_at=<ISO> -->
MARKER_RE='<!-- claudius-review:v=1:head_sha=[0-9a-f]{40}:base_sha=[0-9a-f]{40}:round=[0-9]+:posted_at=[^ ]+ -->'

# Build candidate list: each item = {body, timestamp, surface}
candidates=$(printf '%s' "$raw" | jq -c --arg re "$MARKER_RE" '
  def with_marker(surface): map(select(.body != null and (.body | test($re))) | {body, timestamp, surface: surface});

  ( [ .data.repository.pullRequest.reviews.nodes[]?
        | select(.isMinimized == false)
        | {body: .body, timestamp: .submittedAt} ] | with_marker("reviews") )
  +
  ( [ .data.repository.pullRequest.comments.nodes[]?
        | {body: .body, timestamp: .createdAt} ] | with_marker("comments") )
  +
  ( [ .data.repository.pullRequest.reviewThreads.nodes[]?.comments.nodes[]?
        | {body: .body, timestamp: .createdAt} ] | with_marker("threads") )
' 2>/dev/null || echo "[]")

if [[ -z "$candidates" || "$candidates" == "null" ]]; then
  candidates="[]"
fi

# Pick the latest by timestamp
chosen=$(printf '%s' "$candidates" | jq -c '
  if length == 0 then null
  else (sort_by(.timestamp) | last)
  end' 2>/dev/null || echo "null")

if [[ "$chosen" != "null" && -n "$chosen" ]]; then
  body=$(printf '%s' "$chosen" | jq -r '.body // ""')
  surface=$(printf '%s' "$chosen" | jq -r '.surface // "none"')

  # Parse the marker fields (first match wins; markers are single-line)
  marker_line=$(printf '%s\n' "$body" | grep -oE "$MARKER_RE" | head -1)

  if [[ -n "$marker_line" ]]; then
    head_sha=$(printf '%s' "$marker_line" | sed -nE 's/.*head_sha=([0-9a-f]{40}).*/\1/p')
    round=$(printf '%s' "$marker_line" | sed -nE 's/.*round=([0-9]+).*/\1/p')
    [[ -z "$round" ]] && round=0

    # Resolve latest_reviewed_commit = head_sha^ when worktree is available
    lrc="$head_sha"
    if [[ -n "$WORKTREE" && -d "$WORKTREE" ]]; then
      resolved=$(git -C "$WORKTREE" log "$head_sha^" --max-count=1 --format="%H" 2>/dev/null || true)
      if [[ -n "$resolved" ]]; then
        lrc="$resolved"
      fi
    fi

    _emit_result "$head_sha" "$lrc" "$surface" "$round"
    exit 0
  fi
fi

# --- Fallback: legacy reviews-only timestamp heuristic ---
# Source = "none" (signals fallback was used, not that reviews were chosen)
fallback=$(printf '%s' "$raw" | jq -c '
  [ .data.repository.pullRequest.reviews.nodes[]?
      | select(.isMinimized == false)
      | {body: .body, timestamp: .submittedAt, commitOid: .commit.oid} ]
  | sort_by(.timestamp)
  | if length == 0 then null else last end
' 2>/dev/null || echo "null")

if [[ "$fallback" != "null" && -n "$fallback" ]]; then
  fb_commit=$(printf '%s' "$fallback" | jq -r '.commitOid // ""')
  fb_body=$(printf '%s' "$fallback" | jq -r '.body // ""')
  round=$(printf '%s' "$fb_body" | head -5 | grep -oiE 'Round[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+' || echo "0")
  [[ -z "$round" ]] && round=0

  lrc=""
  if [[ -n "$fb_commit" ]]; then
    if [[ -n "$WORKTREE" && -d "$WORKTREE" ]]; then
      lrc=$(git -C "$WORKTREE" log "$fb_commit^" --max-count=1 --format="%H" 2>/dev/null || true)
    fi
    [[ -z "$lrc" ]] && lrc="$fb_commit"
  fi

  _emit_result "$HEAD_REF_OID" "$lrc" "none" "$round"
  exit 0
fi

# Nothing found anywhere
_emit_result "$HEAD_REF_OID" "" "none" 0
exit 0
