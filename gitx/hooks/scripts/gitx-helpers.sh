#!/bin/bash
# Plugin-specific helper functions for gitx hooks
# Contains _init_stop(), _post_init(), validate_git_repo(), get_pr_turn()

# Common validation: git repo
validate_git_repo() {
  local WORKTREE="$1"
  log_section "Git Validation"
  if ! git -C "$WORKTREE" rev-parse --git-dir &>/dev/null; then
    log_error "Not a git repository: $WORKTREE"
    log_exit 2 "not a git repository"
    echo "Error: '$WORKTREE' is not a git repository" >&2
    exit 2
  fi
  log_info "Git repository validated"
}

# Stop event: parse transcript for last gitx command
_init_stop() {
  TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
  log_debug "TRANSCRIPT_PATH" "$TRANSCRIPT_PATH"

  if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
    log_info "No transcript path or file not found, exiting"
    log_exit 0 "no transcript"
    exit 0
  fi

  log_section "Command Detection"

  # Get the full command line: /gitx:command-name [args...]
  # Match the command and everything after it until end of line
  PROMPT=$(tail -100 "$TRANSCRIPT_PATH" | rp -oP "(?<=\"content\":\")/?${_plugin_lower}:[a-z:-]+[^\n]*(?=\"(\}\r?\n|\}?,\"))" | tail -1 || echo "")
  log_debug "PROMPT" "$PROMPT"

  # Extract command name: /gitx:command-name -> command-name
  COMMAND=$(echo "$PROMPT" | sed -n "s|^/\?${_plugin_lower}:\([a-z:-]*\).*|\1|p")
  # Extract arguments (everything after the command name)
  ARGS=""
  if [[ -n "$PROMPT" ]]; then
    ARGS="${PROMPT#/$COMMAND}"
    ARGS="${ARGS# }"  # Trim leading space
  fi
}

# Post-init: git validation, branch detection, metadata
_post_init() {
  validate_git_repo "$WORKTREE"

  CURRENT_BRANCH=$(git -C "$WORKTREE" branch --show-current 2>/dev/null || echo "")
  log_debug "CURRENT_BRANCH" "$CURRENT_BRANCH"

  log_section "Metadata"
  METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"
  log_debug "METADATA_FILE" "$METADATA_FILE"
  log_debug "METADATA_EXISTS" "$(test -f "$METADATA_FILE" && echo "yes" || echo "no")"

  if [[ "$HOOK_EVENT_TYPE" == "Stop" ]] || [[ "$HOOK_EVENT_TYPE" == "PostToolUse" ]]; then
    if [[ ! -f "$METADATA_FILE" ]]; then
      log_info "No metadata file, exiting"
      log_exit 0 "no metadata"
      exit 0
    fi
  fi

  export CURRENT_BRANCH
  export METADATA_FILE
}

# Get PR turn from metadata file
# Returns turn value or "UNKNOWN" if not found
get_pr_turn() {
  local metadata="${METADATA_FILE:-$WORKTREE/.thoughts/pr/metadata.yaml}"
  if [[ -f "$metadata" ]]; then
    yq -r '.turn // "UNKNOWN"' "$metadata"
  else
    echo "NO_METADATA"
  fi
}
