#!/bin/bash
# GitHub CLI operations for PR reviews
# Usage: gh-review-operations.sh <operation> [args...]
# Operations: check-owner, list-reviews, create-comment, create-pr-comment, minimize-comment, get-latest-comment

set -uo pipefail

OPERATION="${1:-}"
shift || true

case "$OPERATION" in
  check-owner)
    # Check if current user is the PR owner
    # Usage: check-owner <pr_number>
    PR="${1:-}"
    if [[ -z "$PR" ]]; then
      echo '{"error": "PR number required"}' >&2
      exit 1
    fi

    OWNER=$(gh pr view "$PR" --json author --jq '.author.login' 2>/dev/null)
    REVIEWER=$(gh auth status --json hosts --jq '.hosts."github.com"[0].login' 2>/dev/null)

    if [[ "$OWNER" == "$REVIEWER" ]]; then
      echo '{"is_owner": true, "user": "'"$REVIEWER"'", "can_approve": false}'
    else
      echo '{"is_owner": false, "user": "'"$REVIEWER"'", "can_approve": true}'
    fi
    ;;

  list-reviews)
    # List non-minimized reviews and review threads from metadata file
    # Usage: list-reviews <worktree>
    # Returns: { reviews: [...], reviewThreads: [...], latestMinimizedReview: {...} }
    # Exit 1 if metadata file not found (caller should trigger metadata-fetcher agent)
    WORKTREE="${1:-.}"

    # Convert Windows paths to bash format
    WORKTREE=$(echo "$WORKTREE" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g')

    # Resolve relative paths
    if [[ "$WORKTREE" == "." ]] || [[ -z "$WORKTREE" ]]; then
      WORKTREE=$(pwd | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g')
    fi

    METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"

    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata file not found", "needs_fetch": true}' >&2
      exit 1
    fi

    # Check for error or noPr status in metadata
    has_error=$(yq -r '.error // false' "$METADATA_FILE" 2>/dev/null)
    no_pr=$(yq -r '.noPr // false' "$METADATA_FILE" 2>/dev/null)

    if [[ "$has_error" == "true" ]]; then
      error_msg=$(yq -r '.message // "Unknown error"' "$METADATA_FILE")
      echo "{\"error\": \"$error_msg\", \"needs_fetch\": true}" >&2
      exit 1
    fi

    if [[ "$no_pr" == "true" ]]; then
      echo '{"error": "No PR exists for this branch", "needs_fetch": false}' >&2
      exit 1
    fi

    # Extract non-minimized reviews from metadata (latestReviews field - already filtered)
    reviews=$(yq -o=json '.latestReviews // []' "$METADATA_FILE" 2>/dev/null)
    if [[ -z "$reviews" ]] || [[ "$reviews" == "null" ]]; then
      reviews="[]"
    fi

    # Extract non-minimized review threads (reviewThreads field - already filtered)
    review_threads=$(yq -o=json '.reviewThreads // []' "$METADATA_FILE" 2>/dev/null)
    if [[ -z "$review_threads" ]] || [[ "$review_threads" == "null" ]]; then
      review_threads="[]"
    fi

    # Extract latest minimized review for context
    latest_minimized=$(yq -o=json '.latestMinimizedReview // null' "$METADATA_FILE" 2>/dev/null)
    if [[ -z "$latest_minimized" ]]; then
      latest_minimized="null"
    fi

    # Return combined JSON
    jq -n --argjson reviews "$reviews" --argjson threads "$review_threads" --argjson minimized "$latest_minimized" \
      '{ reviews: $reviews, reviewThreads: $threads, latestMinimizedReview: $minimized }'
    ;;

  create-comment)
    # Create a PR review comment (for owner reviewing own PR)
    # Usage: create-comment <pr_number> <body>
    PR="${1:-}"
    BODY="${2:-}"
    if [[ -z "$PR" ]] || [[ -z "$BODY" ]]; then
      echo '{"error": "PR number and body required"}' >&2
      exit 1
    fi

    gh pr review "$PR" -c -b "$BODY"
    echo '{"success": true}'
    ;;

  create-pr-comment)
    # Create a regular PR comment (response to review)
    # Usage: create-pr-comment <pr_number> <body>
    PR="${1:-}"
    BODY="${2:-}"
    if [[ -z "$PR" ]] || [[ -z "$BODY" ]]; then
      echo '{"error": "PR number and body required"}' >&2
      exit 1
    fi

    gh pr comment "$PR" -b "$BODY"
    echo '{"success": true}'
    ;;

  minimize-comment)
    # Minimize (hide) a comment with a reason
    # Usage: minimize-comment <node_id> <reason>
    # Reasons: RESOLVED, OUTDATED, OFF_TOPIC, ABUSE, SPAM, DUPLICATE
    NODE_ID="${1:-}"
    REASON="${2:-RESOLVED}"
    if [[ -z "$NODE_ID" ]]; then
      echo '{"error": "Node ID required"}' >&2
      exit 1
    fi

    gh api graphql -f query='
    mutation($commentId: ID!, $reason: ReportedContentClassifiers!) {
      minimizeComment(input: {subjectId: $commentId, classifier: $reason}) {
        minimizedComment {
          isMinimized
          minimizedReason
        }
      }
    }' -f commentId="$NODE_ID" -f reason="$REASON"
    ;;

  get-latest-comment)
    # Get the latest non-review comment on a PR
    # Usage: get-latest-comment <pr_number>
    PR="${1:-}"
    if [[ -z "$PR" ]]; then
      echo '{"error": "PR number required"}' >&2
      exit 1
    fi

    gh pr view "$PR" --json comments --jq '.comments[-1] | {nodeId: .id, body: .body, createdAt: .createdAt, author: .author.login}'
    ;;

  *)
    echo "Usage: gh-review-operations.sh <operation> [args...]" >&2
    echo "Operations:" >&2
    echo "  check-owner <pr>           - Check if current user owns the PR" >&2
    echo "  list-reviews <worktree>    - List reviews from metadata file" >&2
    echo "  create-comment <pr> <body> - Create review comment (owner mode)" >&2
    echo "  create-pr-comment <pr> <body> - Create regular PR comment" >&2
    echo "  minimize-comment <node_id> [reason] - Minimize a comment" >&2
    echo "  get-latest-comment <pr>    - Get latest non-review comment" >&2
    exit 1
    ;;
esac
