#!/bin/bash
# Build the review prompt from PR metadata
# Reads from .thoughts/pr/metadata.yaml and outputs a formatted prompt for pr-review-toolkit

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

# Check if metadata file exists
if [[ ! -f "$METADATA_FILE" ]]; then
  echo "error: Metadata file not found: $METADATA_FILE" >&2
  exit 1
fi

# Read values from YAML using yq
PR_NUMBER=$(yq '.pr' "$METADATA_FILE")
LATEST_REVIEWED_COMMIT=$(yq '.latestReviewedCommit // ""' "$METADATA_FILE")

# Get arrays as JSON strings (for jq processing below)
LATEST_REVIEWS=$(yq -o=json '.latestReviews // []' "$METADATA_FILE")
LATEST_COMMENTS=$(yq -o=json '.latestComments // []' "$METADATA_FILE")

# Check if reviews exist
reviews_count=$(echo "$LATEST_REVIEWS" | jq 'length')
has_reviews=false
if [[ "$reviews_count" -gt 0 ]]; then
  has_reviews=true
fi

# Check if comments exist
comments_count=$(echo "$LATEST_COMMENTS" | jq 'length')
has_comments=false
if [[ "$comments_count" -gt 0 ]]; then
  has_comments=true
fi

# Build the prompt
cat << EOF
PR: $PR_NUMBER

Output to $WORKTREE/.thoughts/pr/review.md
EOF

# Add review range if there was a previous review
if [[ -n "$LATEST_REVIEWED_COMMIT" ]] && [[ "$LATEST_REVIEWED_COMMIT" != "null" ]]; then
  cat << EOF

Review all changes from commit <commit>$LATEST_REVIEWED_COMMIT</commit> to tip of PR
EOF
fi

# Add latest reviews if they exist
if [[ "$has_reviews" == "true" ]]; then
  # Format reviews as readable text
  REVIEWS_TEXT=$(echo "$LATEST_REVIEWS" | jq -r '.[] | "- [\(.timestamp)] \(.body | gsub("\n"; "\n  "))"')
  cat << EOF

Consider also your latest reviews

Latest Reviews:

<reviews>
$REVIEWS_TEXT
</reviews>
EOF
fi

# Add latest comments (responses) if they exist
if [[ "$has_comments" == "true" ]]; then
  # Format comments as readable text
  COMMENTS_TEXT=$(echo "$LATEST_COMMENTS" | jq -r '.[] | "- [\(.timestamp)] @\(.author): \(.body | gsub("\n"; "\n  "))"')
  cat << EOF

Consider also the responses to the latest reviews

Latest Responses:

<responses>
$COMMENTS_TEXT
</responses>
EOF
fi

exit 0
