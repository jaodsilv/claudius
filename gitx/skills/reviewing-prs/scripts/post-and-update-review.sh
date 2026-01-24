#!/bin/bash
# Post review to PR, hide old comments/reviews, and update metadata
# Takes worktree path as input

set -uo pipefail

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# Get worktree from argument or use current directory
WORKTREE="${1:-.}"
WORKTREE=$(convert_path "$WORKTREE")

# Resolve to absolute path if relative
if [[ "$WORKTREE" == "." ]] || [[ -z "$WORKTREE" ]]; then
  WORKTREE=$(convert_path "$(pwd)")
elif [[ ! "$WORKTREE" = /* ]]; then
  WORKTREE=$(convert_path "$(cd "$WORKTREE" && pwd)")
fi

METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"
REVIEW_FILE="$WORKTREE/.thoughts/pr/review.md"

# Check required files exist
if [[ ! -f "$METADATA_FILE" ]]; then
  echo "error: Metadata file not found: $METADATA_FILE" >&2
  exit 1
fi

if [[ ! -f "$REVIEW_FILE" ]]; then
  echo "error: Review file not found: $REVIEW_FILE" >&2
  exit 1
fi

# Read values from metadata
PR_NUMBER=$(yq '.pr' "$METADATA_FILE")
BRANCH=$(yq '.branch' "$METADATA_FILE")

if [[ -z "$PR_NUMBER" ]] || [[ "$PR_NUMBER" == "null" ]]; then
  echo "error: PR number not found in metadata" >&2
  exit 1
fi

# Get repo info from git remote
remote_url=$(git -C "$WORKTREE" remote get-url origin 2>/dev/null || echo "")
if [[ -z "$remote_url" ]]; then
  echo "error: Could not determine remote URL" >&2
  exit 1
fi

# Parse owner/repo from remote URL
if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  REPO_OWNER="${BASH_REMATCH[1]}"
  REPO_NAME="${BASH_REMATCH[2]}"
else
  echo "error: Could not parse repository from remote URL: $remote_url" >&2
  exit 1
fi

# --- Phase 1: Post the review ---

echo "Posting review to PR #$PR_NUMBER..."
if ! gh pr review -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --comment --body-file "$REVIEW_FILE"; then
  echo "error: Failed to post review" >&2
  exit 1
fi
echo "Review posted successfully"

# --- Phase 2: Fetch and update review fields ---

echo "Updating review metadata..."

# Fetch reviews using GraphQL
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
reviews=$(echo "$reviews_result" | jq '[.data.repository.pullRequest.reviews.nodes[] | select(.isMinimized == false) | {nodeid: .id, body: .body, timestamp: .submittedAt, commitOid: .commit.oid}]' 2>/dev/null)

if [[ -z "$reviews" ]] || [[ "$reviews" == "null" ]]; then
  reviews="[]"
fi

# Sort reviews by timestamp ascending
reviews=$(echo "$reviews" | jq 'sort_by(.timestamp)')

# Calculate latest reviewed commit and review count
latest_reviewed_commit=""
reviews_length=$(echo "$reviews" | jq 'length')

review_count=0
if [[ "$reviews_length" -gt 0 ]]; then
  latest_review_body=$(echo "$reviews" | jq -r '.[-1].body // ""')
  round_match=$(echo "$latest_review_body" | head -5 | grep -oiE 'Round[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+')

  if [[ -n "$round_match" ]]; then
    review_count="$round_match"
  else
    review_count=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json reviews --jq '.reviews | length' 2>/dev/null || echo "0")
  fi
fi

if [[ "$reviews_length" -gt 0 ]]; then
  latest_review_commit=$(echo "$reviews" | jq -r '.[-1].commitOid // empty')

  if [[ -n "$latest_review_commit" ]]; then
    latest_reviewed_commit=$(git -C "$WORKTREE" log "$latest_review_commit^" --max-count=1 --format="%H" 2>/dev/null || echo "")
    if [[ -z "$latest_reviewed_commit" ]]; then
      latest_reviewed_commit="$latest_review_commit"
    fi
  fi
fi

# Fetch comments
comments_json=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json comments --jq '.comments // []' 2>/dev/null | tr -d '\r')
if [[ -z "$comments_json" ]] || [[ "$comments_json" == "null" ]]; then
  comments_json="[]"
fi

# Filter comments after oldest review
oldest_review_timestamp=""
if [[ "$review_count" -gt 0 ]]; then
  oldest_review_timestamp=$(echo "$reviews" | jq -r '.[0].timestamp // empty')
fi

if [[ -n "$oldest_review_timestamp" ]]; then
  filtered_comments=$(echo "$comments_json" | jq --arg oldest "$oldest_review_timestamp" '[.[] | select(.createdAt > $oldest) | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]')
else
  filtered_comments=$(echo "$comments_json" | jq '[.[] | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]')
fi

if [[ -z "$filtered_comments" ]] || [[ "$filtered_comments" == "null" ]]; then
  filtered_comments="[]"
fi

# Update review fields in metadata
yq -i ".latestReviews = $reviews" "$METADATA_FILE"
yq -i ".latestReviewedCommit = $(if [[ -z "$latest_reviewed_commit" ]]; then echo 'null'; else echo "\"$latest_reviewed_commit\""; fi)" "$METADATA_FILE"
yq -i ".reviewCount = $review_count" "$METADATA_FILE"
yq -i ".latestComments = $filtered_comments" "$METADATA_FILE"

# Delete review.md to prevent stale content on next run
rm -f "$REVIEW_FILE"

echo '{"status": "ok", "message": "Review posted and metadata updated"}'
exit 0
