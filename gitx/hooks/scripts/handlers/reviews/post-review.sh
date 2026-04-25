#!/bin/bash
# Post-review handler: refreshes PR metadata after review
# Runs in post-hook context where WORKTREE, METADATA_FILE, CLAUDE_PLUGIN_ROOT are available

source "$SCRIPTS_DIR/lib/hook-output.sh"
log_section "Post-Review Handler"

# Resolve REPO from --repo flag or git remote
REPO_FLAG=$(get_flag_value "$ARGS" "--repo")
PR_FLAG=$(get_flag_value "$ARGS" "--pr")

if [[ -n "$REPO_FLAG" ]]; then
  REPO_OWNER="${REPO_FLAG%%/*}"
  REPO_NAME="${REPO_FLAG#*/}"
  log_info "Using repo from flag: $REPO_FLAG"
else
  remote_url=$(git -C "$WORKTREE" remote get-url origin 2>/dev/null || echo "")
  if [[ -z "$remote_url" ]]; then
    log_info "Could not determine remote URL, skipping metadata refresh"
    log_exit 0 "no remote"
    exit 0
  fi
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
  else
    log_info "Could not parse repository from remote URL, skipping metadata refresh"
    log_exit 0 "bad remote"
    exit 0
  fi
fi

if [[ -n "$PR_FLAG" ]]; then
  PR_NUMBER="$PR_FLAG"
  log_info "Using PR from flag: $PR_NUMBER"
elif [[ -f "$METADATA_FILE" ]]; then
  META_JSON=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh" \
    --worktree "$WORKTREE" --get pr --format json 2>/dev/null)
  PR_NUMBER=$(echo "$META_JSON" | jq -r '.pr // ""')
  log_info "Using PR from metadata: $PR_NUMBER"
else
  PR_NUMBER=""
fi

if [[ -z "$PR_NUMBER" ]] || [[ "$PR_NUMBER" == "null" ]]; then
  log_info "No PR number available, skipping metadata refresh"
  log_exit 0 "no pr number"
  exit 0
fi

# --- Fetch and update review fields ---
log_info "Updating review metadata..."

reviews_query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviews(last: 100) {
        nodes {
          id
          body
          submittedAt
          isMinimized
          commit {
            oid
          }
        }
      }
    }
  }
}'

reviews_result=$(gh api graphql -f query="$reviews_query" -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F number="$PR_NUMBER" 2>/dev/null | tr -d '\r')
reviews=$(echo "$reviews_result" | jq '[.data.repository.pullRequest.reviews.nodes[] | select(.isMinimized == false) | {nodeid: .id, body: .body, timestamp: .submittedAt, commitOid: .commit.oid}]' 2>/dev/null | tr -d '\r')

if [[ -z "$reviews" ]] || [[ "$reviews" == "null" ]]; then
  reviews="[]"
fi

reviews=$(echo "$reviews" | jq 'sort_by(.timestamp)' | tr -d '\r')

latest_reviewed_commit=""
reviews_length=$(echo "$reviews" | jq 'length' | tr -d '\r')

review_count=0
if [[ "$reviews_length" -gt 0 ]]; then
  latest_review_body=$(echo "$reviews" | jq -r '.[-1].body // ""' | tr -d '\r')
  round_match=$(echo "$latest_review_body" | head -5 | grep -oiE 'Round[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+')

  if [[ -n "$round_match" ]]; then
    review_count="$round_match"
  else
    review_count=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json reviews --jq '.reviews | length' 2>/dev/null || echo "0")
  fi
fi

if [[ "$reviews_length" -gt 0 ]]; then
  latest_review_commit=$(echo "$reviews" | jq -r '.[-1].commitOid // empty' | tr -d '\r')

  if [[ -n "$latest_review_commit" ]]; then
    latest_reviewed_commit=$(git -C "$WORKTREE" log "$latest_review_commit^" --max-count=1 --format="%H" 2>/dev/null || echo "")
    if [[ -z "$latest_reviewed_commit" ]]; then
      latest_reviewed_commit="$latest_review_commit"
    fi
  fi
fi

comments_json=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json comments --jq '.comments // []' 2>/dev/null | tr -d '\r')
if [[ -z "$comments_json" ]] || [[ "$comments_json" == "null" ]]; then
  comments_json="[]"
fi

oldest_review_timestamp=""
if [[ "$review_count" -gt 0 ]]; then
  oldest_review_timestamp=$(echo "$reviews" | jq -r '.[0].timestamp // empty')
fi

if [[ -n "$oldest_review_timestamp" ]]; then
  filtered_comments=$(echo "$comments_json" | jq --arg oldest "$oldest_review_timestamp" '[.[] | select(.createdAt > $oldest) | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]' | tr -d '\r')
else
  filtered_comments=$(echo "$comments_json" | jq '[.[] | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]' | tr -d '\r')
fi

if [[ -z "$filtered_comments" ]] || [[ "$filtered_comments" == "null" ]]; then
  filtered_comments="[]"
fi

# Write to metadata only if file exists (Branch A may have no local metadata)
if [[ -f "$METADATA_FILE" ]]; then
  yq -i ".latestReviews = $reviews" "$METADATA_FILE"
  yq -i ".latestReviewedCommit = $(if [[ -z "$latest_reviewed_commit" ]]; then echo 'null'; else echo "\"$latest_reviewed_commit\""; fi)" "$METADATA_FILE"
  yq -i ".reviewCount = $review_count" "$METADATA_FILE"
  yq -i ".latestComments = $filtered_comments" "$METADATA_FILE"
  log_info "Metadata updated"
else
  log_info "No local metadata file, skipping metadata writes"
fi

log_info "Review metadata refresh complete"
