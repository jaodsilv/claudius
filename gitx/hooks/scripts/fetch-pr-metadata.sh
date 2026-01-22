#!/bin/bash
# Fetch PR metadata and output to .thoughts/pr/metadata.yaml
# Takes a worktree path as input and finds the PR for its current branch

# Don't use set -e to allow graceful error handling
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

# Output directory and file
OUTPUT_DIR="$WORKTREE/.thoughts/pr"
OUTPUT_FILE="$OUTPUT_DIR/metadata.yaml"

# Write error to output file and stderr
write_error() {
  local message="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$OUTPUT_DIR"
  yq -n ".error = true | .message = \"$message\" | .timestamp = \"$timestamp\"" > "$OUTPUT_FILE"

  echo "error: $message" >&2
  exit 1
}

# Write "no PR" status to output file (not an error, just informational)
write_no_pr() {
  local message="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$OUTPUT_DIR"
  jq -n \
    --arg branch "$BRANCH" \
    --arg worktree "$WORKTREE" \
    --arg message "$message" \
    --arg timestamp "$timestamp" \
    '{
      pr: null,
      branch: $branch,
      worktree: $worktree,
      noPr: true,
      message: $message,
      timestamp: $timestamp
    }' | yq -P > "$OUTPUT_FILE"

  echo "info: $message"
  exit 0
}

# Phase 1: Environment Check

# Check worktree exists
if [[ ! -d "$WORKTREE" ]]; then
  write_error "Worktree directory does not exist: $WORKTREE"
fi

# Check gh CLI
if ! command -v gh &> /dev/null; then
  write_error "gh CLI is not installed"
fi

# Check gh authentication
if ! gh auth status &> /dev/null; then
  write_error "gh CLI is not authenticated. Run 'gh auth login'"
fi

# Check if worktree is in a git repo
if ! git -C "$WORKTREE" rev-parse --git-dir &> /dev/null; then
  write_error "Not in a git repository: $WORKTREE"
fi

# Get current branch
BRANCH=$(git -C "$WORKTREE" branch --show-current 2>/dev/null || echo "")
if [[ -z "$BRANCH" ]]; then
  write_error "Could not determine current branch in worktree: $WORKTREE"
fi

# Parse issue reference from branch name
# Patterns: issue-123, #123, /123-, feature/issue-123-desc, bugfix/123-desc
LINKED_ISSUE=""
if [[ "$BRANCH" =~ issue-([0-9]+) ]]; then
  LINKED_ISSUE="${BASH_REMATCH[1]}"
elif [[ "$BRANCH" =~ \#([0-9]+) ]]; then
  LINKED_ISSUE="${BASH_REMATCH[1]}"
elif [[ "$BRANCH" =~ /([0-9]+)- ]]; then
  LINKED_ISSUE="${BASH_REMATCH[1]}"
fi

# Get repo info from git remote
remote_url=$(git -C "$WORKTREE" remote get-url origin 2>/dev/null || echo "")
if [[ -z "$remote_url" ]]; then
  write_error "Could not determine remote URL"
fi

# Parse owner/repo from remote URL (handles both HTTPS and SSH formats)
# HTTPS: https://github.com/owner/repo.git
# SSH: git@github.com:owner/repo.git
if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  REPO_OWNER="${BASH_REMATCH[1]}"
  REPO_NAME="${BASH_REMATCH[2]}"
else
  write_error "Could not parse repository from remote URL: $remote_url"
fi

# Phase 2: Find PR for branch

PR_NUMBER=$(gh pr list -R "$REPO_OWNER/$REPO_NAME" --head "$BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null)
if [[ -z "$PR_NUMBER" ]] || [[ "$PR_NUMBER" == "null" ]]; then
  write_no_pr "No open PR found for branch: $BRANCH"
fi

# Phase 3: Fetch PR Metadata

pr_metadata=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json title,author,body,baseRefName,statusCheckRollup 2>/dev/null)
if [[ -z "$pr_metadata" ]]; then
  write_error "Could not fetch PR metadata for PR #$PR_NUMBER"
fi

PR_TITLE=$(echo "$pr_metadata" | jq -r '.title')
PR_AUTHOR=$(echo "$pr_metadata" | jq -r '.author.login')
PR_DESCRIPTION=$(echo "$pr_metadata" | jq -r '.body // ""')
PR_BASE=$(echo "$pr_metadata" | jq -r '.baseRefName')
STATUS_CHECKS=$(echo "$pr_metadata" | jq -c '.statusCheckRollup // []')

# Phase 4: Fetch Reviews and Review Threads (GraphQL)

reviews_query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewDecision
      reviews(last: 100) {
        nodes {
          id
          body
          submittedAt
          isMinimized
          minimizedReason
          author {
            login
          }
          commit {
            oid
          }
        }
      }
      reviewThreads(last: 100) {
        nodes {
          id
          path
          line
          isResolved
          isCollapsed
          comments(first: 1) {
            nodes {
              id
              body
              createdAt
              author {
                login
              }
            }
          }
        }
      }
    }
  }
}'

reviews_result=$(gh api graphql -f query="$reviews_query" -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F number="$PR_NUMBER" 2>/dev/null)

# Extract review decision (APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or null)
review_decision=$(echo "$reviews_result" | jq -r '.data.repository.pullRequest.reviewDecision // empty' 2>/dev/null)

# Extract non-minimized reviews with author
reviews=$(echo "$reviews_result" | jq '[.data.repository.pullRequest.reviews.nodes[] | select(.isMinimized == false) | {nodeid: .id, body: .body, timestamp: .submittedAt, commitOid: .commit.oid, author: .author.login}]' 2>/dev/null)

if [[ -z "$reviews" ]] || [[ "$reviews" == "null" ]]; then
  reviews="[]"
fi

# Sort reviews by timestamp ascending
reviews=$(echo "$reviews" | jq 'sort_by(.timestamp)')

# Extract latest minimized review (for reference by reviewing skill)
latest_minimized_review=$(echo "$reviews_result" | jq '[.data.repository.pullRequest.reviews.nodes[] | select(.isMinimized == true)] | sort_by(.submittedAt) | last // null | if . then {nodeid: .id, body: .body, timestamp: .submittedAt, author: .author.login, minimizedReason: .minimizedReason} else null end' 2>/dev/null)

if [[ -z "$latest_minimized_review" ]] || [[ "$latest_minimized_review" == "null" ]]; then
  latest_minimized_review="null"
fi

# Extract non-collapsed review threads (isCollapsed filters minimized inline comments)
review_threads=$(echo "$reviews_result" | jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isCollapsed == false) | {nodeid: .id, path: .path, line: .line, isResolved: .isResolved, body: .comments.nodes[0].body, timestamp: .comments.nodes[0].createdAt, author: .comments.nodes[0].author.login}]' 2>/dev/null)

if [[ -z "$review_threads" ]] || [[ "$review_threads" == "null" ]]; then
  review_threads="[]"
fi

# Phase 5: Calculate Latest Reviewed Commit

latest_reviewed_commit=""
reviews_length=$(echo "$reviews" | jq 'length')

# Determine Review Count
review_count=0
if [[ "$reviews_length" -gt 0 ]]; then
  # Check for "Round X" in the latest review body (first 5 lines)
  latest_review_body=$(echo "$reviews" | jq -r '.[-1].body // ""')
  round_match=$(echo "$latest_review_body" | head -5 | grep -oiE 'Round[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+')

  if [[ -n "$round_match" ]]; then
    review_count="$round_match"
  else
    # Fall back to gh pr view count
    review_count=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json reviews --jq '.reviews | length' 2>/dev/null || echo "0")
  fi
fi

if [[ "$reviews_length" -gt 0 ]]; then
  # Get the latest review's commit
  latest_review_commit=$(echo "$reviews" | jq -r '.[-1].commitOid // empty')

  if [[ -n "$latest_review_commit" ]]; then
    # Find the commit BEFORE the latest review commit (the last commit that was reviewed)
    latest_reviewed_commit=$(git -C "$WORKTREE" log "$latest_review_commit^" --max-count=1 --format="%H" 2>/dev/null || echo "")

    # If we couldn't get the parent, use the review commit itself
    if [[ -z "$latest_reviewed_commit" ]]; then
      latest_reviewed_commit="$latest_review_commit"
    fi
  fi
fi

# Phase 6: Fetch Latest Comments

comments_json=$(gh pr view -R "$REPO_OWNER/$REPO_NAME" "$PR_NUMBER" --json comments --jq '.comments // []' 2>/dev/null)
if [[ -z "$comments_json" ]] || [[ "$comments_json" == "null" ]]; then
  comments_json="[]"
fi

# Get oldest non-resolved review timestamp
oldest_review_timestamp=""
if [[ "$review_count" -gt 0 ]]; then
  oldest_review_timestamp=$(echo "$reviews" | jq -r '.[0].timestamp // empty')
fi

# Split comments into two arrays:
# - filtered_comments (latestComments): comments AFTER oldest review - guides current review
# - historical_comments: comments BEFORE oldest review - decision documentation
if [[ -n "$oldest_review_timestamp" ]]; then
  filtered_comments=$(echo "$comments_json" | jq --arg oldest "$oldest_review_timestamp" '[.[] | select(.createdAt > $oldest) | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]')
  historical_comments=$(echo "$comments_json" | jq --arg oldest "$oldest_review_timestamp" '[.[] | select(.createdAt <= $oldest) | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]')
else
  filtered_comments=$(echo "$comments_json" | jq '[.[] | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body}]')
  historical_comments="[]"
fi

if [[ -z "$filtered_comments" ]] || [[ "$filtered_comments" == "null" ]]; then
  filtered_comments="[]"
fi

if [[ -z "$historical_comments" ]] || [[ "$historical_comments" == "null" ]]; then
  historical_comments="[]"
fi

# Phase 7: Determine Turn
turn="REVIEW"
comments_count=$(echo "$filtered_comments" | jq 'length')

# Phase 8: Get Latest Commit
latest_commit=$(git -C "$WORKTREE" log HEAD --max-count=1 --format="%H" 2>/dev/null || echo "")

# Phase 9: Get CI Status
ci_status="[]"

# Get run list for IDs
ci_runs=$(gh run list -R "$REPO_OWNER/$REPO_NAME" -b "$BRANCH" --json databaseId,url,workflowName 2>/dev/null || echo "[]")

if [[ "$STATUS_CHECKS" != "[]" ]] && [[ "$STATUS_CHECKS" != "null" ]]; then
  ci_status=$(echo "$STATUS_CHECKS" | jq --argjson runs "$ci_runs" '
    [.[] |
      . as $check |
      (($check.detailsUrl // "") | if test("/runs/[0-9]+") then capture("/runs/(?<id>[0-9]+)") | .id else null end) as $runId |
      {
        name: ($check.name // $check.context // "unknown"),
        workflowName: ($check.workflowName // ""),
        status: ($check.status // (if $check.state then "COMPLETED" else null end)),
        conclusion: ($check.conclusion // $check.state // null),
        typename: $check.__typename,
        detailsUrl: $check.detailsUrl,
        runId: $runId,
        url: (if $runId then (($runs // [])[] | select(.databaseId == ($runId | tonumber)) | .url) // $check.detailsUrl else $check.detailsUrl end)
      }
    ]
  ')
fi

if [[ -z "$ci_status" ]] || [[ "$ci_status" == "null" ]]; then
  ci_status="[]"
fi

# Phase 9b: Fetch CI Failure Logs
CI_LOGS_DIR="$WORKTREE/.thoughts/pr/ci"
mkdir -p "$CI_LOGS_DIR"

# Get failed checks with valid runIds
failed_checks=$(echo "$ci_status" | jq -r '.[] | select(.runId != null and .conclusion != null and .conclusion != "SUCCESS" and .conclusion != "CANCELLED" and .conclusion != "SKIPPED" and .conclusion != "NEUTRAL" and .conclusion != "") | "\(.name)\t\(.runId)"')

if [[ -n "$failed_checks" ]]; then
  echo "Fetching CI failure logs..."
  while IFS=$'\t' read -r check_name run_id; do
    if [[ -n "$run_id" ]] && [[ "$run_id" != "null" ]]; then
      # Sanitize name for filename (replace spaces and special chars with underscore)
      safe_name=$(echo "$check_name" | sed 's/[^a-zA-Z0-9._-]/_/g')
      log_file="$CI_LOGS_DIR/${safe_name}.${run_id}.log"

      echo "  Fetching logs for $check_name (run $run_id)..."
      if gh run view -R "$REPO_OWNER/$REPO_NAME" "$run_id" --log-failed > "$log_file" 2>&1; then
        echo "    Saved to $log_file"
      else
        echo "    Failed to fetch logs (may not have failed steps)"
        rm -f "$log_file"
      fi
    fi
  done <<< "$failed_checks"
fi

# Phase 10: Determine Turn from CI Status
pending_checks=0
failing_checks=0
if [[ "$STATUS_CHECKS" != "[]" ]] && [[ "$STATUS_CHECKS" != "null" ]]; then
  failing_checks=$(echo "$STATUS_CHECKS" | jq '[.[] | select(
    (.__typename == "CheckRun" and .conclusion != "SUCCESS" and .conclusion != "CANCELLED" and .conclusion != "SKIPPED" and .conclusion != "NEUTRAL" and .conclusion != "" and .conclusion != null) or
    (.__typename == "StatusContext" and .state != "SUCCESS" and .state != "PENDING" and .state != null)
  )] | length')
  pending_checks=$(echo "$STATUS_CHECKS" | jq '[.[] | select(
    (.__typename == "CheckRun" and .status != "COMPLETED" and .status != null and .status != "") or
    (.__typename == "StatusContext" and .state == "PENDING")
  )] | length')
fi

if [[ "$pending_checks" -gt 0 ]]; then
  turn="CI-PENDING"
elif [[ "$failing_checks" -gt 0 ]]; then
  turn="CI-REVIEW"
elif [[ "$review_count" -eq 0 ]]; then
  turn="REVIEW"
elif [[ "$comments_count" -eq 0 ]]; then
  turn="AUTHOR"
else
  # Compare timestamps
  latest_review_timestamp=$(echo "$reviews" | jq -r '.[-1].timestamp // empty')
  latest_comment_timestamp=$(echo "$filtered_comments" | jq -r '.[-1].timestamp // empty')

  if [[ -n "$latest_review_timestamp" ]] && [[ -n "$latest_comment_timestamp" ]]; then
    if [[ "$latest_review_timestamp" > "$latest_comment_timestamp" ]]; then
      turn="AUTHOR"
    else
      turn="REVIEW"
    fi
  elif [[ -n "$latest_review_timestamp" ]]; then
    turn="AUTHOR"
  fi
fi

# Phase 11: Output YAML

mkdir -p "$OUTPUT_DIR"

# Get current timestamp for createdAt/updatedAt
current_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Preserve existing resolveLevel if metadata exists, otherwise default to "all"
existing_resolve_level="all"
if [[ -f "$OUTPUT_FILE" ]]; then
  existing_resolve_level=$(yq -r '.resolveLevel // "all"' "$OUTPUT_FILE" 2>/dev/null || echo "all")
fi

jq -n \
  --argjson pr "$PR_NUMBER" \
  --arg author "$PR_AUTHOR" \
  --arg branch "$BRANCH" \
  --arg worktree "$WORKTREE" \
  --arg title "$PR_TITLE" \
  --arg description "$PR_DESCRIPTION" \
  --arg base "$PR_BASE" \
  --arg linkedIssue "$LINKED_ISSUE" \
  --argjson latestReviews "$reviews" \
  --argjson reviewThreads "$review_threads" \
  --argjson latestMinimizedReview "$latest_minimized_review" \
  --arg latestReviewedCommit "$latest_reviewed_commit" \
  --argjson ciStatus "$ci_status" \
  --argjson latestComments "$filtered_comments" \
  --argjson historicalComments "$historical_comments" \
  --argjson reviewCount "$review_count" \
  --arg turn "$turn" \
  --arg latestCommit "$latest_commit" \
  --arg reviewDecision "$review_decision" \
  --arg resolveLevel "$existing_resolve_level" \
  --arg timestamp "$current_timestamp" \
  '{
    pr: $pr,
    author: $author,
    branch: $branch,
    worktree: $worktree,
    title: $title,
    description: $description,
    base: $base,
    linkedIssue: (if $linkedIssue == "" then null else ($linkedIssue | tonumber) end),
    latestReviews: $latestReviews,
    reviewThreads: $reviewThreads,
    latestMinimizedReview: $latestMinimizedReview,
    latestReviewedCommit: (if $latestReviewedCommit == "" then null else $latestReviewedCommit end),
    ciStatus: $ciStatus,
    latestComments: $latestComments,
    historicalComments: $historicalComments,
    reviewCount: $reviewCount,
    turn: $turn,
    latestCommit: (if $latestCommit == "" then null else $latestCommit end),
    reviewDecision: (if $reviewDecision == "" then null else $reviewDecision end),
    approved: false,
    resolveLevel: $resolveLevel,
    createdAt: $timestamp,
    updatedAt: $timestamp
  }' | yq -P > "$OUTPUT_FILE"

# Output success message
echo "{\"status\": \"ok\", \"message\": \"PR metadata written to $OUTPUT_FILE\"}"
exit 0
