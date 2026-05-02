#!/bin/bash
# Sourced by gitx-pre-command.sh for /gitx:commit-push
# Handles mode detection, validation, and minimal context injection

# Environment provided by gitx-pre-command.sh:
#   WORKTREE - resolved git worktree path
#   ARGS     - command arguments (everything after /gitx:commit-push)
#   METADATA_FILE - path to PR metadata file

source "$SCRIPTS_DIR/lib/hook-output.sh"
source "$SCRIPTS_DIR/lib/args-validator.sh"

log_section "commit-push-pre Handler"

# ============================================================================
# Parse mode from arguments using has_flag
# ============================================================================
MODE="single-commit"  # Default mode

if has_flag "$ARGS" "--files"; then
  MODE="lists"
  log_debug "MODE" "lists (explicit files)"
elif has_flag "$ARGS" "--context"; then
  MODE="context-description"
  log_debug "MODE" "context-description"
elif has_flag "$ARGS" "--multi"; then
  MODE="multi-commit"
  log_debug "MODE" "multi-commit"
else
  log_debug "MODE" "single-commit (default)"
fi

# Check for --no-push flag
if has_flag "$ARGS" "--no-push"; then
  log_debug "NO_PUSH" "true"
fi

# ============================================================================
# Get git status via commit-push.sh --info
# ============================================================================
log_section "Git Status"

STATUS_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/commits/commit-push.sh"

log_debug "STATUS_SCRIPT" "$STATUS_SCRIPT"

STATUS=$(bash "$STATUS_SCRIPT" --info 2>/dev/null)
STATUS_EXIT=$?

log_debug "STATUS_EXIT" "$STATUS_EXIT"
log_json "STATUS" "$STATUS"

if [[ $STATUS_EXIT -eq 1 ]]; then
  # Nothing to commit
  log_error "Nothing to commit"
  hook_output_block "Nothing to commit, working tree clean"
  log_exit 2 "nothing to commit"
  exit 2
fi

if [[ $STATUS_EXIT -eq 2 ]]; then
  # Error
  ERROR_MSG=$(echo "$STATUS" | jq -r '.message // "Unknown error"')
  log_error "Status error: $ERROR_MSG"
  hook_output_block "Error: $ERROR_MSG"
  log_exit 2 "status error"
  exit 2
fi

# ============================================================================
# Mode-specific processing
# ============================================================================
log_section "Mode Processing: $MODE"

case "$MODE" in
  lists)
    # Parse file groups from --files arguments
    # Format: --files a.ts b.ts --files c.ts d.ts
    # Each --files creates a separate group

    GROUPS_JSON="["
    FIRST_GROUP=true

    # Extract each --files group using perl for robust parsing
    while IFS= read -r group; do
      if [[ -n "$group" ]]; then
        log_debug "GROUP" "$group"

        # Build JSON array for this group
        FILES_JSON="["
        FIRST_FILE=true
        for file in $group; do
          # Skip flags
          [[ "$file" =~ ^-- ]] && continue
          [[ -z "$file" ]] && continue

          # Normalise: strip leading "./" and trailing "/"
          norm="$file"
          norm="${norm#./}"
          trailing_slash=false
          if [[ "$norm" == */ ]]; then
            trailing_slash=true
            norm="${norm%/}"
          fi
          if [[ -z "$norm" || "$norm" == "." ]]; then
            log_error "Invalid file arg: $file"
            hook_output_block "Invalid file argument: '$file' (cannot be empty or '.')"
            log_exit 2 "invalid file arg"
            exit 2
          fi

          # 1. Try exact match against staged / unstaged / untracked
          HAS_STAGED=$(echo "$STATUS"   | jq -r --arg f "$norm" '.staged_files[]?   | select(.file == $f) | .file')
          HAS_UNSTAGED=$(echo "$STATUS" | jq -r --arg f "$norm" '.unstaged_files[]? | select(.file == $f) | .file')
          HAS_UNTRACKED=$(echo "$STATUS"| jq -r --arg f "$norm" '.untracked_files[]? | select(. == $f)')

          if [[ -n "$HAS_STAGED" || -n "$HAS_UNSTAGED" || -n "$HAS_UNTRACKED" ]]; then
            if $FIRST_FILE; then FIRST_FILE=false; else FILES_JSON+=","; fi
            FILES_JSON+="$(printf '%s' "$norm" | jq -Rs .)"
            continue
          fi

          # 2. Exact-match miss. Determine if arg is a directory request.
          is_dir=false
          if $trailing_slash; then
            is_dir=true
          elif [[ -n "${WORKTREE:-}" && -d "$WORKTREE/$norm" ]]; then
            is_dir=true
          fi

          if ! $is_dir; then
            log_error "No changes for file: $file"
            hook_output_block "No changes found for file: $file"
            log_exit 2 "file has no changes"
            exit 2
          fi

          # 3. Expand directory: collect any changed file under "$norm/"
          EXPANDED=$(echo "$STATUS" | jq -c --arg p "$norm/" '
            [
              (.staged_files[]?    | select(.file       | startswith($p)) | .file),
              (.unstaged_files[]?  | select(.file       | startswith($p)) | .file),
              (.untracked_files[]? | select(.            | startswith($p)))
            ] | unique
          ')
          EXPANDED_COUNT=$(echo "$EXPANDED" | jq 'length')

          if [[ "$EXPANDED_COUNT" -eq 0 ]]; then
            log_error "No changes under directory: $file"
            hook_output_block "No changes found under directory: $file"
            log_exit 2 "directory has no changes"
            exit 2
          fi

          log_debug "DIR_EXPAND" "$file -> $EXPANDED_COUNT files"

          while IFS= read -r expanded_file; do
            [[ -z "$expanded_file" ]] && continue
            if $FIRST_FILE; then FIRST_FILE=false; else FILES_JSON+=","; fi
            FILES_JSON+="$(printf '%s' "$expanded_file" | jq -Rs .)"
          done < <(echo "$EXPANDED" | jq -r '.[]')
        done
        FILES_JSON+="]"

        if $FIRST_GROUP; then
          FIRST_GROUP=false
        else
          GROUPS_JSON+=","
        fi
        GROUPS_JSON+="$FILES_JSON"
      fi
    done < <(echo "$ARGS" | perl -nle 'while(/--files\s+((?:(?!(?:^|\s)--)\S+\s*)+)/g){$s=$1; $s=~s/\s+$//; print $s}')

    GROUPS_JSON+="]"
    log_json "GROUPS_JSON" "$GROUPS_JSON"

    # Validate at least one group was found
    GROUP_COUNT=$(echo "$GROUPS_JSON" | jq 'length')
    if [[ "$GROUP_COUNT" -eq 0 ]]; then
      log_error "No file groups specified"
      hook_output_block "No files specified. Use: /gitx:commit-push --files file1.ts file2.ts"
      log_exit 2 "no files specified"
      exit 2
    fi
    ;;

  context-description)
    # Extract description from --context "..."
    DESCRIPTION=$(echo "$ARGS" | sed -n 's/.*--context[[:space:]]*"\([^"]*\)".*/\1/p')

    if [[ -z "$DESCRIPTION" ]]; then
      # Try without quotes
      DESCRIPTION=$(echo "$ARGS" | sed -n 's/.*--context[[:space:]]*\([^[:space:]][^[:space:]]*\).*/\1/p')
    fi

    log_debug "DESCRIPTION" "$DESCRIPTION"

    if [[ -z "$DESCRIPTION" ]]; then
      log_error "No description provided"
      hook_output_block "No description provided. Use: /gitx:commit-push --context \"description of changes\""
      log_exit 2 "no description"
      exit 2
    fi
    ;;

  multi-commit)
    CONTEXT=""
    ;;

  single-commit)
    # Determine file list based on staged vs unstaged
    STAGED_COUNT=$(echo "$STATUS" | jq -r '.staged_count')

    if [[ "$STAGED_COUNT" -gt 0 ]]; then
      # Use staged files only
      FILES=$(echo "$STATUS" | jq -c '[.staged_files[].file]')
      log_debug "FILES (staged)" "$FILES"
    else
      # Use all changed files (unstaged + untracked)
      UNSTAGED=$(echo "$STATUS" | jq -c '[.unstaged_files[].file // empty]')
      UNTRACKED=$(echo "$STATUS" | jq -c '.untracked_files // []')
      FILES=$(echo "$UNSTAGED $UNTRACKED" | jq -s 'add | unique')
      log_debug "FILES (all)" "$FILES"
    fi

    # Convert to lists mode with single group
    CONTEXT="--files $FILES"
    log_json "CONTEXT" "$CONTEXT"

    # ============================================================================
    # Output context for command
    # ============================================================================
    log_section "Hook Output"
    hook_output_context "$CONTEXT"
    log_exit 0 "context injected"
    exit 0
    ;;
esac

log_section "Hook Output"
log_exit 0 "nothing to inject"

exit 0
