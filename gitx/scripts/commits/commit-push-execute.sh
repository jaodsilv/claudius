#!/bin/bash
# Direct execution script for git commit/push operations
# Performs: stage -> commit -> push for all commit pairs
#
# Usage: commit-push-execute.sh <base64-encoded-json>
#
# Input format (base64 encoded):
# {
#   "no_push": false,
#   "pairs": [
#     {"files": ["src/a.ts"], "message": "feat: add feature"},
#     {"files": ["test.ts"], "message": "test: add tests"}
#   ]
# }

# Parse --plugin-root flag
for _arg in "$@"; do
  if [[ "$_arg" == --plugin-root=* ]]; then
    _PLUGIN_ROOT_PARAM="${_arg#--plugin-root=}"
    break
  fi
done

# Priority: env var > --plugin-root flag > self-location fallback
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${_PLUGIN_ROOT_PARAM:-$(cd "$(dirname "$0")/../.." && pwd)}}"

set -uo pipefail

# Get script directory and source libraries
LOGGING_PATH=""
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/logging.sh" ]]; then
  LOGGING_PATH="${CLAUDE_PLUGIN_ROOT}/scripts/lib/logging.sh"
else
  LOGGING_PATH="${CLAUDE_PLUGIN_ROOT}/hooks/scripts/lib/logging.sh"
fi
source "$LOGGING_PATH" || exit 1
log_init "commit-push-execute"

# Get base64 argument - try from args first, then from env var
COMMIT_PAIRS_B64="${2:-${COMMIT_PAIRS_B64:-}}"
log_section "Input Processing"
log_debug "COMMIT_PAIRS_B64" "$COMMIT_PAIRS_B64"

if [[ -z "$COMMIT_PAIRS_B64" ]]; then
  echo "Error: No commit pairs provided"
  echo "Usage: commit-push-execute.sh <base64-encoded-json>"
  log_exit 2 "no input"
  exit 1
fi

# Decode commit pairs
COMMIT_PAIRS=$(echo "$COMMIT_PAIRS_B64" | base64 -d 2>/dev/null)
if [[ $? -ne 0 ]]; then
  log_error "Failed to decode commit pairs"
  echo "Error: Invalid commit pairs encoding"
  log_exit 2 "decode failed"
  exit 1
fi

log_json "COMMIT_PAIRS" "$COMMIT_PAIRS"

# Validate JSON
if ! echo "$COMMIT_PAIRS" | jq . >/dev/null 2>&1; then
  log_error "Invalid commit pairs JSON"
  echo "Error: Invalid commit pairs format"
  log_exit 2 "invalid json"
  exit 1
fi

# Extract options from commit pairs
NO_PUSH=$(echo "$COMMIT_PAIRS" | jq -r '.no_push // false')
PAIRS=$(echo "$COMMIT_PAIRS" | jq -c '.pairs[]')

log_debug "NO_PUSH" "$NO_PUSH"
log_json "PAIRS" "$PAIRS"

PAIR_COUNT=$(echo "$PAIRS" | grep -c '.')
if [[ "$PAIR_COUNT" -eq 0 ]]; then
  log_error "No commit pairs provided"
  echo "Error: No commit pairs to execute"
  log_exit 2 "no pairs"
  exit 1
fi

# ============================================================================
# Execute commits
# ============================================================================
log_section "Execute Commits"

COMMITS_RESULT=()
INDEX=0

while IFS= read -r pair; do
  log_section "Commit $INDEX"
  log_json "pair" "$pair"

  # Extract files and message
  FILES=$(echo "$pair" | jq -r '.files[]')
  MESSAGE=$(echo "$pair" | jq -r '.message')

  log_debug "FILES" "$FILES"
  log_debug "MESSAGE" "$MESSAGE"

  # Stage files
  log_info "Staging files..."
  STAGE_ERROR=""
  for file in $FILES; do
    # Remove carriage returns (Windows line-ending cleanup)
    file=$(echo "$file" | tr -d '\r')
    log_debug "Staging" "$file"
    if ! git add -- "$file" 2>&1; then
      STAGE_ERROR="Failed to stage: $file"
      break
    fi
  done

  if [[ -n "$STAGE_ERROR" ]]; then
    log_error "$STAGE_ERROR"
    echo "Error staging files: $STAGE_ERROR"
    echo ""
    echo "Please check the files and try again."
    log_exit 2 "stage failed"
    exit 1
  fi

  # Create commit
  log_info "Creating commit..."
  COMMIT_OUTPUT=$(git commit -m "$MESSAGE" 2>&1)
  COMMIT_EXIT=$?

  if [[ $COMMIT_EXIT -ne 0 ]]; then
    log_error "Commit failed: $COMMIT_OUTPUT"
    echo "Error creating commit:"
    echo "$COMMIT_OUTPUT"
    echo ""
    echo "Please check the error and try again."
    log_exit 2 "commit failed"
    exit 1
  fi

  # Extract commit SHA
  SHA=$(git rev-parse --short HEAD)
  log_info "Created commit $SHA"

  # Build result entry
  FILES_JSON=$(echo "$pair" | jq -c '.files')
  COMMITS_RESULT+=("{\"sha\":\"$SHA\",\"message\":$(echo "$MESSAGE" | jq -Rs .),\"files\":$FILES_JSON}")

  INDEX=$((INDEX + 1))
done < <(echo "$PAIRS" | jq -c '.[]')

# ============================================================================
# Push to remote
# ============================================================================
PUSHED=false
PUSH_ERROR=""

if [[ "$NO_PUSH" != "true" ]]; then
  log_section "Push to Remote"

  # Check if upstream exists
  UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")

  if [[ -z "$UPSTREAM" ]]; then
    # No upstream, push with -u
    BRANCH=$(git branch --show-current)
    log_info "No upstream, pushing with -u origin $BRANCH"
    PUSH_OUTPUT=$(git push -u origin "$BRANCH" 2>&1)
    PUSH_EXIT=$?
  else
    log_info "Pushing to $UPSTREAM"
    PUSH_OUTPUT=$(git push 2>&1)
    PUSH_EXIT=$?
  fi

  log_debug "PUSH_EXIT" "$PUSH_EXIT"
  log_debug "PUSH_OUTPUT" "$PUSH_OUTPUT"

  if [[ $PUSH_EXIT -eq 0 ]]; then
    log_info "Pushed successfully"
    PUSHED=true
  else
    log_error "Push failed: $PUSH_OUTPUT"
    PUSH_ERROR="$PUSH_OUTPUT"
  fi
else
  log_info "Skipping push (--no-push flag)"
fi

# ============================================================================
# Update PR metadata
# ============================================================================
PR_UPDATED=false

if [[ "$PUSHED" == "true" ]]; then
  # Use WORKTREE from parent if available, otherwise fall back to project dir or pwd
  WORKTREE="${WORKTREE:-$(pwd)}"
  METADATA_FILE="${METADATA_FILE:-$WORKTREE/.thoughts/pr/metadata.yaml}"

  if [[ -f "$METADATA_FILE" ]]; then
    log_section "Update PR Metadata"
    log_debug "METADATA_FILE" "$METADATA_FILE"

    METADATA_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/scripts/handlers/metadata-operations.sh"

    if [[ -f "$METADATA_SCRIPT" ]]; then
      if bash "$METADATA_SCRIPT" post-push "$WORKTREE" 2>&1; then
        log_info "PR metadata updated"
        PR_UPDATED=true
      else
        log_warn "Failed to update PR metadata"
      fi
    else
      log_warn "Metadata script not found"
    fi
  else
    log_info "No PR metadata file found, skipping update"
  fi
fi

# ============================================================================
# Build result message
# ============================================================================
log_section "Build Result"

# Format commits JSON
COMMITS_JSON="[$(IFS=,; echo "${COMMITS_RESULT[*]}")]"
log_json "COMMITS_JSON" "$COMMITS_JSON"

# Build human-readable summary
SUMMARY="## Commits Created\n\n"
INDEX=1
while IFS= read -r commit; do
  SHA=$(echo "$commit" | jq -r '.sha')
  MSG=$(echo "$commit" | jq -r '.message')
  FILE_COUNT=$(echo "$commit" | jq -r '.files | length')
  FILES_LIST=$(echo "$commit" | jq -r '.files[]' | sed 's/^/  - /')

  SUMMARY+="### Commit $INDEX: $SHA\n"
  SUMMARY+="**Message**: $MSG\n"
  SUMMARY+="**Files** ($FILE_COUNT):\n$FILES_LIST\n\n"
  INDEX=$((INDEX + 1))
done < <(echo "$COMMITS_JSON" | jq -c '.[]')

SUMMARY+="---\n\n"

# Add push/PR status
if [[ -n "$PUSH_ERROR" ]]; then
  SUMMARY+="**Push Status**: Failed\n"
  SUMMARY+="**Error**: $PUSH_ERROR\n\n"
  SUMMARY+="Use the AskUserQuestion tool to ask the user what to do:\n"
  SUMMARY+="- Option A: git pull --rebase then retry push\n"
  SUMMARY+="- Option B: git push --force-with-lease\n"
elif [[ "$PUSHED" == "true" ]]; then
  BRANCH=$(git branch --show-current)
  SUMMARY+="**Push Status**: Pushed to origin/$BRANCH\n"
  if [[ "$PR_UPDATED" == "true" ]]; then
    SUMMARY+="**PR Status**: Turn updated to CI-PENDING\n"
  fi
elif [[ "$NO_PUSH" == "true" ]]; then
  SUMMARY+="**Push Status**: Skipped (--no-push)\n"
fi

# ============================================================================
# Output result
# ============================================================================
log_section "Output"

# Output human-readable summary
echo -e "$SUMMARY"

if [[ -n "$PUSH_ERROR" ]]; then
  log_exit 0 "commits created, push failed"
  exit 0
else
  echo "This command completed successfully. There is nothing else to do. You should conclude this processing NOW."
  log_exit 0 "execution complete"
  exit 0
fi
