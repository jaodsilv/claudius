#!/bin/bash
# Inject diffs for commit message generation or file selection
# Called by commit-push-pretool.sh for Skill(gitx:committing-conventionally) or Task agents

set -uo pipefail

# Get script directory and source logging
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"
log_init "commit-push-inject-diff"

# Set hook event type
export HOOK_EVENT_TYPE="PreToolUse"

# Read JSON input from stdin
INPUT=$(cat)
log_section "Input Processing"
log_json "stdin_input" "$INPUT"

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

log_debug "TOOL_NAME" "$TOOL_NAME"

# ============================================================================
# Get all changed files with status
# ============================================================================
log_section "Get Git Status"

STATUS_SCRIPT="$HANDLERS_DIR/commit-push.sh"

STATUS=$(bash "$STATUS_SCRIPT" --info 2>/dev/null)
STATUS_EXIT=$?

log_debug "STATUS_EXIT" "$STATUS_EXIT"

if [[ $STATUS_EXIT -ne 0 ]]; then
  log_info "No changes found, passing through"
  log_exit 0 "no changes"
  exit 0
fi

# ============================================================================
# Determine which files to get diffs for
# ============================================================================
log_section "Determine Files"

# Check if specific files are requested (from skill args)
ARGS=""
if [[ "$TOOL_NAME" == "Skill" ]]; then
  ARGS=$(echo "$TOOL_INPUT" | jq -r '.args // ""')
elif [[ "$TOOL_NAME" == "Task" ]]; then
  ARGS=$(echo "$TOOL_INPUT" | jq -r '.prompt // ""')
fi

log_debug "ARGS" "$ARGS"

# Try to extract file list from args (files may be in args as space-separated list)
FILES_TO_DIFF=()

if [[ -n "$ARGS" ]] && [[ "$ARGS" != "null" ]]; then
  # Check if args contains a file list (JSON array or space-separated)
  if echo "$ARGS" | jq -e 'type == "array"' &>/dev/null; then
    # JSON array
    while IFS= read -r file; do
      FILES_TO_DIFF+=("$file")
    done < <(echo "$ARGS" | jq -r '.[]')
  elif [[ "$ARGS" =~ \[.*\] ]]; then
    # Embedded JSON array in string
    FILES_JSON=$(echo "$ARGS" | grep -oP '\[.*?\]' | head -1)
    while IFS= read -r file; do
      FILES_TO_DIFF+=("$file")
    done < <(echo "$FILES_JSON" | jq -r '.[]' 2>/dev/null)
  fi
fi

log_debug "FILES_TO_DIFF count" "${#FILES_TO_DIFF[@]}"

# ============================================================================
# Build diffs output
# ============================================================================
log_section "Build Diffs"

DIFFS=""

if [[ ${#FILES_TO_DIFF[@]} -gt 0 ]]; then
  # Get diffs for specific files
  log_info "Getting diffs for ${#FILES_TO_DIFF[@]} specific files"

  for file in "${FILES_TO_DIFF[@]}"; do
    [[ -z "$file" ]] && continue
    log_debug "Getting diff for" "$file"

    # Try cached diff first, then regular diff
    DIFF=$(git diff --cached -- "$file" 2>/dev/null || true)
    if [[ -z "$DIFF" ]]; then
      DIFF=$(git diff -- "$file" 2>/dev/null || true)
    fi
    if [[ -z "$DIFF" ]]; then
      # New file - show content
      if [[ -f "$file" ]]; then
        DIFF="New file - content preview:\n$(head -100 "$file" 2>/dev/null || echo "(binary or unreadable)")"
      else
        DIFF="(file not found or deleted)"
      fi
    fi

    DIFFS+="=== File: $file ===\n$DIFF\n\n"
  done
else
  # Get diffs for all changed files
  log_info "Getting diffs for all changed files"

  # Staged files
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    log_debug "Getting staged diff for" "$file"
    DIFF=$(git diff --cached -- "$file" 2>/dev/null || echo "(no diff available)")
    DIFFS+="=== File: $file (staged) ===\n$DIFF\n\n"
  done < <(echo "$STATUS" | jq -r '.staged_files[]?.file // empty')

  # Unstaged files
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    log_debug "Getting unstaged diff for" "$file"
    DIFF=$(git diff -- "$file" 2>/dev/null || echo "(no diff available)")
    DIFFS+="=== File: $file (unstaged) ===\n$DIFF\n\n"
  done < <(echo "$STATUS" | jq -r '.unstaged_files[]?.file // empty')

  # Untracked files (show preview)
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    log_debug "Getting preview for untracked" "$file"
    if [[ -f "$file" ]]; then
      PREVIEW=$(head -50 "$file" 2>/dev/null || echo "(binary or unreadable)")
      DIFFS+="=== File: $file (new/untracked) ===\n$PREVIEW\n\n"
    fi
  done < <(echo "$STATUS" | jq -r '.untracked_files[]? // empty')
fi

# ============================================================================
# Output context
# ============================================================================
log_section "Output"

if [[ -n "$DIFFS" ]]; then
  # Prepare context string
  CONTEXT="Changed Files with Diffs:\n\n$DIFFS"
  log_info "Injecting diffs (${#DIFFS} chars)"
  hook_output_context "$CONTEXT"
else
  log_info "No diffs to inject"
fi

log_exit 0 "diffs injected"
exit 0
