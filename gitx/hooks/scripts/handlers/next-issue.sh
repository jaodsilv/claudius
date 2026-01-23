#!/bin/bash
# Handler for /gitx:next-issue command
# Verify 1+ issues, pick issue, block always

log_section "Next-Issue Handler"

log_info "Checking for open issues..."
ISSUE_COUNT=$(gh issue list --state open --json number --jq 'length' 2>/dev/null || echo "0")
log_debug "ISSUE_COUNT" "$ISSUE_COUNT"

if [[ "$ISSUE_COUNT" -eq 0 ]]; then
  log_info "No open issues found"
  log_exit 0 "no issues - block with JSON"
  echo '{"decision": "block", "reason": "No open issues found."}'
  exit 0
fi

# Pick issue using standard labels/milestone (can be customized)
# Priority: P0 > P1 > P2 > unlabeled
# Within priority: oldest first

log_info "Searching for highest priority issue..."
ISSUE=$(gh issue list --state open --label "P0" --json number,title --jq '.[0] // empty' 2>/dev/null)
log_debug "P0_ISSUE" "$ISSUE"

if [[ -z "$ISSUE" ]]; then
  ISSUE=$(gh issue list --state open --label "P1" --json number,title --jq '.[0] // empty' 2>/dev/null)
  log_debug "P1_ISSUE" "$ISSUE"
fi
if [[ -z "$ISSUE" ]]; then
  ISSUE=$(gh issue list --state open --label "P2" --json number,title --jq '.[0] // empty' 2>/dev/null)
  log_debug "P2_ISSUE" "$ISSUE"
fi
if [[ -z "$ISSUE" ]]; then
  ISSUE=$(gh issue list --state open --json number,title --jq '.[0] // empty' 2>/dev/null)
  log_debug "UNLABELED_ISSUE" "$ISSUE"
fi

if [[ -n "$ISSUE" ]]; then
  NUMBER=$(echo "$ISSUE" | jq -r '.number')
  TITLE=$(echo "$ISSUE" | jq -r '.title')
  log_info "Selected issue #$NUMBER: $TITLE"
  # Get issue details for the reason
  ISSUE_BODY=$(gh issue view "$NUMBER" --json body,labels,assignees --jq '{body: .body[0:200], labels: [.labels[].name], assignees: [.assignees[].login]}' 2>/dev/null || echo "{}")
  log_exit 0 "block with JSON"
  echo "{\"decision\": \"block\", \"reason\": \"Next issue: #$NUMBER - $TITLE\"}"
  exit 0
fi

log_exit 0 "no issues found - block with JSON"
echo '{"decision": "block", "reason": "No open issues found."}'
exit 0
