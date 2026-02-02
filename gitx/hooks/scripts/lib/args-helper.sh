#!/bin/bash
# Shared library with helper functions for gitx hooks

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  path=$(echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g')
  log_debug "CONVERTED PATH" "$path"
  echo "$path"
}

# Resolve relative paths to absolute (relative to CWD, not script dir)
resolve_path() {
  local path="$1"
  local CWD="$2"
  if [[ ! "$path" = /* ]]; then
    CWD_CONVERTED=$(convert_path "$CWD")
    output=$(convert_path "$(cd "$CWD_CONVERTED" && cd "$path" 2>/dev/null && pwd)")
    log_debug "RESOLVED PATH" "$output"
    echo "$output"
  else
    log_debug "RESOLVED PATH" "$path"
    echo "$path"
  fi
}

# Parse worktree from arguments or use CWD
# Supports: --worktree <path>, positional <path>, or default to CWD
get_worktree() {
  local CWD="$1"
  local ARGS="$2"
  local WORKTREE="$CWD"
  if [[ "$ARGS" =~ --worktree[[:space:]]+([^[:space:]]+) ]]; then
    WORKTREE="${BASH_REMATCH[1]}"
    log_debug "WORKTREE (from --worktree)" "$WORKTREE"
  elif [[ -n "$ARGS" ]]; then
    # First positional argument might be a worktree path
    FIRST_ARG=$(echo "$ARGS" | awk '{print $1}')
    # Check if it looks like a path (starts with ., /, or drive letter)
    if [[ "$FIRST_ARG" =~ ^[./] ]] || [[ "$FIRST_ARG" =~ ^[A-Za-z]: ]]; then
      WORKTREE="$FIRST_ARG"
      log_debug "WORKTREE (from positional)" "$WORKTREE"
    else
      log_debug "WORKTREE (from CWD)" "$WORKTREE"
    fi
  else
    log_debug "WORKTREE (from CWD)" "$WORKTREE"
  fi
  echo "$(resolve_path "$(convert_path "$WORKTREE")" "$CWD")"
}

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

# Validate if the prompt, skill, or agent is a gitx entity
validate_gitx_entity() {
  local SKILL="$1"
  log_section "Gitx Entity Validation"
  # Check if this is a gitx entity
  if [[ ! "$SKILL" =~ ^[[:space:]]*[/@]?gitx: ]]; then
    log_info "Not a gitx entity, passing through"
    log_exit 0 "not a gitx entity"  
    exit 0
  fi
  log_info "Is a Gitx entity"
}

init() {
  log_debug "HOOK_EVENT_TYPE" "$HOOK_EVENT_TYPE"

  INPUT=$(cat)
  log_section "Input Processing"
  log_json "stdin_input" "$INPUT"

  # Get CWD from input JSON
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  log_debug "CWD" "$CWD"

  # Defining PROMPT = "/?gitx:$COMMAND $ARGS"
  if [[ "$HOOK_EVENT_TYPE" == "UserPromptSubmit" ]]; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
    log_debug "PROMPT" "$PROMPT"

    COMMAND=$(echo "$PROMPT" | sed -n 's|^[[:space:]]*/?/gitx:\([a-z:-]*\).*|\1|p')
    # Extract command name: /gitx:command-name -> command-name
    ARGS=$(echo "$PROMPT" | sed -n 's|^[[:space:]]*/?/gitx:[a-z:-]*[[:space:]]*||p')
  elif [[ "$HOOK_EVENT_TYPE" == "PreToolUse" ]] || [[ "$HOOK_EVENT_TYPE" == "PostToolUse" ]]; then
    # Parse PreToolUse or PostToolUse fields
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
    TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
    log_debug "TOOL_NAME" "$TOOL_NAME"

    SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
    ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
    PROMPT="$SKILL $ARGS"
    COMMAND=$(echo "$SKILL" | sed -n 's|^/?gitx:\([a-z:-]*\).*|\1|p')
  elif [[ "$HOOK_EVENT_TYPE" == "Stop" ]]; then
    TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
    log_debug "TRANSCRIPT_PATH" "$TRANSCRIPT_PATH"

    if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
      log_info "No transcript path or file not found, exiting"
      log_exit 0 "no transcript"
      exit 0
    fi

    # Detect which gitx command was last run and extract arguments
    log_section "Command Detection"

    # Get the full command line: /gitx:command-name [args...]
    # Match the command and everything after it until end of line
    PROMPT=$(tail -100 "$TRANSCRIPT_PATH" | rp -oP '(?<="content":")/?gitx:[a-z:-]+[^\n]*(?="(\}\r?\n|\}?,"))' | tail -1 || echo "")
    log_debug "PROMPT" "$PROMPT"

    # Extract command name: /gitx:command-name -> command-name
    COMMAND=$(echo "$PROMPT" | sed -n 's|^/?gitx:\([a-z:-]*\).*|\1|p')
    # Extract arguments (everything after the command name)
    ARGS=""
    if [[ -n "$PROMPT" ]]; then
      ARGS="${PROMPT#/$COMMAND}"
      ARGS="${ARGS# }"  # Trim leading space
    fi
  fi

  log_debug "COMMAND" "$COMMAND"
  log_debug "ARGS" "$ARGS"

  # Only handle gitx: prefixed skills
  validate_gitx_entity "$PROMPT"

  WORKTREE=$(get_worktree "$CWD" "$ARGS")
  log_debug "WORKTREE" "$WORKTREE"

  validate_git_repo "$WORKTREE"

  # Get current branch for context
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
    
  # Export variables for handler scripts
  export WORKTREE
  export ARGS
  export CWD
  export CURRENT_BRANCH
  export METADATA_FILE
  export GITX_DEBUG
  export GITX_LOG_VERBOSE
  export GITX_LOG_DIR
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