#!/bin/bash
# Shared library with helper functions for plugin hooks
# Contains only utility functions common across all plugins

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  path=$(echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g')
  log_debug "CONVERTED PATH" "$path"
  echo "$path"
}

# Normalize a user-provided file path to a repo-relative, forward-slash path
# suitable for matching against `git diff --name-only` / `git ls-files` output.
# Accepts: D:\..., D:/..., /d/... (Git Bash), ./..., .\..., path\with\backslashes
# Args: $1 = path, $2 = worktree (absolute path to repo root)
normalize_repo_path() {
  local path="$1"
  local worktree="$2"

  path=$(convert_path "$path")
  worktree=$(convert_path "$worktree")
  worktree="${worktree%/}"

  if [[ "$path" == /* && -n "$worktree" && "$path" == "$worktree"/* ]]; then
    path="${path#$worktree/}"
  fi

  path="${path#./}"

  log_debug "NORMALIZED REPO PATH" "$path"
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

  # 1. Check XML tag <worktree>
  if type -t has_xml_tag &>/dev/null && has_xml_tag "$ARGS" "worktree"; then
    WORKTREE=$(get_xml_value "$ARGS" "worktree")
    log_debug "WORKTREE (from <worktree> tag)" "$WORKTREE"
  # 2. Check CLI flag --worktree
  elif [[ "$ARGS" =~ --worktree[[:space:]]+([^[:space:]]+) ]]; then
    WORKTREE="${BASH_REMATCH[1]}"
    log_debug "WORKTREE (from --worktree)" "$WORKTREE"
  elif [[ -n "$ARGS" ]]; then
    # 3. Strip XML tags before positional matching
    local stripped_args="$ARGS"
    if type -t _strip_xml_tags &>/dev/null; then
      stripped_args=$(_strip_xml_tags "$ARGS")
    fi
    FIRST_ARG=$(echo "$stripped_args" | awk '{print $1}')
    if [[ -n "$FIRST_ARG" ]] && { [[ "$FIRST_ARG" =~ ^[./] ]] || [[ "$FIRST_ARG" =~ ^[A-Za-z]: ]]; }; then
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

# Validate if the prompt/skill/agent belongs to the current plugin
# Uses _plugin_lower (set by logging.sh) for the regex and log messages
validate_plugin_entity() {
  local entity="$1"
  log_section "Plugin Entity Validation"
  if [[ ! "$entity" =~ ^[[:space:]]*[/@]?${_plugin_lower}: ]]; then
    log_info "$entity is not a ${_plugin_lower} entity, passing through"
    log_exit 0 "not a ${_plugin_lower} entity"
    exit 0
  fi
  log_info "$entity is a ${_plugin_lower} entity"
}

# Trim leading and trailing newlines from a string
_trim_newlines() {
  local str="$1"
  while [[ "${str:0:1}" == $'\n' ]]; do str="${str:1}"; done
  while [[ -n "$str" && "${str: -1}" == $'\n' ]]; do str="${str%$'\n'}"; done
  echo "$str"
}

# Shared init: parse stdin, extract COMMAND/ARGS, validate entity, resolve worktree
# Extension hooks (define in plugin-helpers.sh BEFORE sourcing args-helper.sh):
#   _init_stop()   — called for Stop events (default: exit 0)
#   _post_init()   — called after shared init completes (e.g., git validation)
init() {
  log_debug "HOOK_EVENT_TYPE" "$HOOK_EVENT_TYPE"

  if [[ -z "${INPUT:-}" ]]; then INPUT=$(cat); fi
  log_section "Input Processing"
  log_json "stdin_input" "$INPUT"

  if [[ -z "${CWD:-}" ]]; then
    CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  fi
  log_debug "CWD" "$CWD"

  if [[ "$HOOK_EVENT_TYPE" == "UserPromptSubmit" ]]; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
    log_debug "PROMPT" "$PROMPT"
    COMMAND=$(echo "$PROMPT" | sed -n "s|^[[:space:]]*/\?/${_plugin_lower}:\([a-z:-]*\).*|\1|p")
    ARGS=$(echo "$PROMPT" | sed -n "s|^[[:space:]]*/\?/${_plugin_lower}:[a-z:-]*[[:space:]]*||p")
  elif [[ "$HOOK_EVENT_TYPE" == "PreToolUse" ]] || [[ "$HOOK_EVENT_TYPE" == "PostToolUse" ]]; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
    TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
    log_debug "TOOL_NAME" "$TOOL_NAME"
    SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
    ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
    PROMPT="$SKILL $ARGS"
    COMMAND=$(echo "$SKILL" | sed -n "s|^/\?${_plugin_lower}:\([a-z:-]*\).*|\1|p")
  elif [[ "$HOOK_EVENT_TYPE" == "Stop" ]]; then
    if type -t _init_stop &>/dev/null; then
      _init_stop
    else
      log_info "Stop event not handled by this plugin"
      log_exit 0 "stop not handled"
      exit 0
    fi
  fi

  ARGS=$(_trim_newlines "$ARGS")

  log_debug "COMMAND" "$COMMAND"
  log_debug "ARGS" "$ARGS"

  validate_plugin_entity "$PROMPT"

  WORKTREE=$(get_worktree "$CWD" "$ARGS")
  log_debug "WORKTREE" "$WORKTREE"

  # Plugin-specific post-init hook
  if type -t _post_init &>/dev/null; then
    _post_init
  fi

  export WORKTREE
  export ARGS
  export CWD
}
