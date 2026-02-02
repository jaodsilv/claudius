#!/bin/bash
# Argument validation for brainstorm plugin

SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}"
source "$SCRIPTS_DIR/lib/hook-output.sh"

validate_required_arg() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    log_error "Missing required argument: $name"
    hook_output_block "Missing required argument: <$name>"
    exit 0
  fi
  return 0
}

validate_one_of() {
  local name="$1"
  local value="$2"
  shift 2
  local options=("$@")
  [[ -z "$value" ]] && return 0
  for opt in "${options[@]}"; do
    if [[ "$value" == "$opt" ]]; then
      return 0
    fi
  done
  local options_str=$(printf ", %s" "${options[@]}")
  options_str="${options_str:2}"
  log_error "Invalid value for $name: $value"
  hook_output_block "Invalid value for $name: '$value'. Expected one of: $options_str"
  exit 0
}

get_flag_value() {
  local args="$1"
  local pattern="$2"
  local regex="${pattern// or /|}"
  local value_regex="(^|[[:space:]])($regex)[[:space:]]+([^[:space:]][^[:space:]]*)"
  if [[ "$args" =~ $value_regex ]]; then
    echo "${BASH_REMATCH[3]}"
  fi
}

get_positional_arg() {
  local args="$1"
  local index="${2:-0}"
  local current=0
  local -a parts
  read -ra parts <<< "$args"
  local skip_next=false
  for part in "${parts[@]}"; do
    if [[ "$skip_next" == "true" ]]; then
      skip_next=false
      continue
    fi
    if [[ "$part" =~ ^- ]]; then
      case "$part" in
        --depth|--output-path|--session-path|--format)
          skip_next=true
          ;;
      esac
      continue
    fi
    if [[ $current -eq $index ]]; then
      echo "$part"
      return 0
    fi
    ((current++))
  done
}
