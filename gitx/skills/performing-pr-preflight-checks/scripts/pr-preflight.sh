#!/bin/bash
# Performs pre-flight checks before PR operations
# Usage: pr-preflight.sh [--for-merge] [pr_number]
# Output: JSON with check results

set -uo pipefail

FOR_MERGE=false
PR_NUMBER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --for-merge)
      FOR_MERGE=true
      shift
      ;;
    *)
      PR_NUMBER="$1"
      shift
      ;;
  esac
done

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>&1)

# Track check results
CHECKS_PASSED=true
CHECKS=()

# Check 1: Not on protected branch
PROTECTED_BRANCHES="main master"
IS_PROTECTED=false
for branch in $PROTECTED_BRANCHES; do
  if [[ "$CURRENT_BRANCH" == "$branch" ]]; then
    IS_PROTECTED=true
    break
  fi
done

if [[ "$IS_PROTECTED" == "true" ]]; then
  CHECKS+=("{\"check\": \"protected_branch\", \"status\": \"FAIL\", \"message\": \"Cannot create PR from $CURRENT_BRANCH branch\"}")
  CHECKS_PASSED=false
else
  CHECKS+=("{\"check\": \"protected_branch\", \"status\": \"PASS\", \"message\": \"Not on protected branch\"}")
fi

# Check 2: Existing PR status
EXISTING_PR=$(gh pr view --json number,url,state 2>/dev/null || echo "")
if [[ -n "$EXISTING_PR" ]] && [[ "$EXISTING_PR" != "null" ]]; then
  PR_NUM=$(echo "$EXISTING_PR" | jq -r '.number')
  PR_STATE=$(echo "$EXISTING_PR" | jq -r '.state')
  PR_URL=$(echo "$EXISTING_PR" | jq -r '.url')

  if [[ "$PR_STATE" == "OPEN" ]]; then
    CHECKS+=("{\"check\": \"existing_pr\", \"status\": \"WARN\", \"message\": \"PR #$PR_NUM already exists\", \"url\": \"$PR_URL\"}")
  else
    CHECKS+=("{\"check\": \"existing_pr\", \"status\": \"PASS\", \"message\": \"No open PR for this branch\"}")
  fi
else
  CHECKS+=("{\"check\": \"existing_pr\", \"status\": \"PASS\", \"message\": \"No existing PR\"}")
fi

# Check 3: Remote sync status
git fetch origin 2>/dev/null

# Check if remote branch exists
REMOTE_EXISTS=$(git ls-remote --heads origin "$CURRENT_BRANCH" 2>/dev/null)
if [[ -z "$REMOTE_EXISTS" ]]; then
  CHECKS+=("{\"check\": \"remote_sync\", \"status\": \"ACTION\", \"message\": \"Remote branch does not exist. Will create on push.\"}")
else
  # Check if local is ahead of remote
  AHEAD_COUNT=$(git rev-list --count "origin/$CURRENT_BRANCH..HEAD" 2>/dev/null || echo "0")
  BEHIND_COUNT=$(git rev-list --count "HEAD..origin/$CURRENT_BRANCH" 2>/dev/null || echo "0")

  if [[ "$AHEAD_COUNT" -gt 0 ]] && [[ "$BEHIND_COUNT" -gt 0 ]]; then
    CHECKS+=("{\"check\": \"remote_sync\", \"status\": \"WARN\", \"message\": \"Branch diverged: $AHEAD_COUNT ahead, $BEHIND_COUNT behind\"}")
  elif [[ "$AHEAD_COUNT" -gt 0 ]]; then
    CHECKS+=("{\"check\": \"remote_sync\", \"status\": \"ACTION\", \"message\": \"Local is $AHEAD_COUNT commits ahead. Push required.\"}")
  elif [[ "$BEHIND_COUNT" -gt 0 ]]; then
    CHECKS+=("{\"check\": \"remote_sync\", \"status\": \"WARN\", \"message\": \"Local is $BEHIND_COUNT commits behind. Pull recommended.\"}")
  else
    CHECKS+=("{\"check\": \"remote_sync\", \"status\": \"PASS\", \"message\": \"In sync with remote\"}")
  fi
fi

# Merge-specific checks
if [[ "$FOR_MERGE" == "true" ]] && [[ -n "$PR_NUMBER" ]]; then
  # Check 4: CI status
  CI_STATUS=$(gh pr checks "$PR_NUMBER" 2>/dev/null || echo "")
  if [[ -n "$CI_STATUS" ]]; then
    FAILED=$(echo "$CI_STATUS" | grep -c "fail\|X" || echo "0")
    PENDING=$(echo "$CI_STATUS" | grep -c "pending\|-" || echo "0")
    PASSED=$(echo "$CI_STATUS" | grep -c "pass\|✓" || echo "0")

    if [[ "$FAILED" -gt 0 ]]; then
      CHECKS+=("{\"check\": \"ci_status\", \"status\": \"WARN\", \"message\": \"$FAILED checks failed, $PASSED passed\"}")
    elif [[ "$PENDING" -gt 0 ]]; then
      CHECKS+=("{\"check\": \"ci_status\", \"status\": \"WARN\", \"message\": \"$PENDING checks pending\"}")
    else
      CHECKS+=("{\"check\": \"ci_status\", \"status\": \"PASS\", \"message\": \"All $PASSED checks passed\"}")
    fi
  fi

  # Check 5: Review approval status
  REVIEWS=$(gh pr view "$PR_NUMBER" --json reviews,reviewDecision 2>/dev/null || echo "")
  if [[ -n "$REVIEWS" ]]; then
    DECISION=$(echo "$REVIEWS" | jq -r '.reviewDecision // "NONE"')
    case "$DECISION" in
      "APPROVED")
        CHECKS+=("{\"check\": \"review_status\", \"status\": \"PASS\", \"message\": \"PR approved\"}")
        ;;
      "CHANGES_REQUESTED")
        CHECKS+=("{\"check\": \"review_status\", \"status\": \"FAIL\", \"message\": \"Changes requested\"}")
        CHECKS_PASSED=false
        ;;
      "REVIEW_REQUIRED")
        CHECKS+=("{\"check\": \"review_status\", \"status\": \"WARN\", \"message\": \"Review required\"}")
        ;;
      *)
        CHECKS+=("{\"check\": \"review_status\", \"status\": \"WARN\", \"message\": \"No reviews yet\"}")
        ;;
    esac
  fi
fi

# Build JSON output
echo "{"
echo "  \"branch\": \"$CURRENT_BRANCH\","
echo "  \"all_passed\": $CHECKS_PASSED,"
echo "  \"checks\": ["

FIRST=true
for check in "${CHECKS[@]}"; do
  if [[ "$FIRST" == "true" ]]; then
    FIRST=false
  else
    echo ","
  fi
  echo -n "    $check"
done

echo ""
echo "  ]"
echo "}"

# Exit code based on results
if [[ "$CHECKS_PASSED" == "false" ]]; then
  exit 1
fi
exit 0
