#!/bin/bash
# Shared library for validating skill arguments
# Provides reusable validation primitives following argument-hint notation rules
#
# Usage:
#   source "$SCRIPTS_DIR/lib/args-validator.sh"
#   validate_required_arg "description" "$value"
#   validate_one_of "mode" "$mode" "squash" "merge" "rebase"
#   validate_mutually_exclusive "$args" "-l or --last" "-c or --single-commit" "-sc or --since-commit"
#   validate_flag_value "$args" "-sc or --since-commit" "commit hash"

# Source hook-output for blocking
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}"
source "$SCRIPTS_DIR/lib/hook-output.sh"

# ============================================================================
# Validate required argument is present
# Usage: validate_required_arg <name> <value>
# Returns: 0 if valid, exits with block if missing
# ============================================================================
validate_required_arg() {
  local name="$1"
  local value="$2"

  if [[ -z "$value" ]]; then
    log_error "Missing required argument: $name"
    hook_output_block "Missing required argument: <$name>"
    exit 0
  fi
  log_debug "VALIDATE_REQUIRED" "$name = '$value' (valid)"
  return 0
}

# ============================================================================
# Validate value is one of allowed options
# Usage: validate_one_of <name> <value> <option1> [<option2> ...]
# Returns: 0 if valid, exits with block if invalid
# ============================================================================
validate_one_of() {
  local name="$1"
  local value="$2"
  shift 2
  local options=("$@")

  # Skip if value is empty (use validate_required_arg for required values)
  [[ -z "$value" ]] && return 0

  for opt in "${options[@]}"; do
    if [[ "$value" == "$opt" ]]; then
      log_debug "VALIDATE_ONE_OF" "$name = '$value' (valid)"
      return 0
    fi
  done

  local options_str
  options_str=$(printf ", %s" "${options[@]}")
  options_str="${options_str:2}"  # Remove leading ", "

  log_error "Invalid value for $name: $value (expected one of: $options_str)"
  hook_output_block "Invalid value for $name: '$value'. Expected one of: $options_str"
  exit 0
}

# ============================================================================
# Validate mutually exclusive flags/options
# Usage: validate_mutually_exclusive <args> <flag1_pattern> <flag2_pattern> ...
# Pattern format: "-l or --last" or regex "-l|--last"
# Returns: 0 if valid, exits with block if multiple present
# ============================================================================
validate_mutually_exclusive() {
  local args="$1"
  shift
  local patterns=("$@")
  local found=()
  local found_names=()

  for pattern in "${patterns[@]}"; do
    # Convert "or" syntax to regex
    local regex="${pattern// or /|}"

    # Check if pattern matches in args
    if [[ "$args" =~ (^|[[:space:]])($regex)([[:space:]]|$) ]]; then
      found+=("$pattern")
      found_names+=("${BASH_REMATCH[2]}")
    fi
  done

  if [[ ${#found[@]} -gt 1 ]]; then
    local found_str
    found_str=$(printf ", %s" "${found_names[@]}")
    found_str="${found_str:2}"

    log_error "Mutually exclusive flags used together: $found_str"
    hook_output_block "Mutually exclusive flags: $found_str (only one allowed)"
    exit 0
  fi

  log_debug "VALIDATE_MUTUAL_EXCL" "valid (found: ${found_names[*]:-none})"
  return 0
}

# ============================================================================
# Validate flag has required value
# Usage: validate_flag_value <args> <flag_pattern> <value_name>
# Pattern format: "-sc or --since-commit"
# Returns: 0 if valid or flag not present, exits with block if flag present without value
# ============================================================================
validate_flag_value() {
  local args="$1"
  local pattern="$2"
  local value_name="$3"

  # Convert "or" syntax to regex
  local regex="${pattern// or /|}"

  # Check if flag is present
  if [[ ! "$args" =~ (^|[[:space:]])($regex)([[:space:]]|$) ]]; then
    log_debug "VALIDATE_FLAG_VALUE" "$pattern not present (skip)"
    return 0
  fi

  local matched_flag="${BASH_REMATCH[2]}"

  # Check if value follows the flag
  # Build regex to capture value after flag
  local value_regex="(^|[[:space:]])($regex)[[:space:]]+([^[:space:]-][^[:space:]]*)"

  if [[ ! "$args" =~ $value_regex ]]; then
    log_error "Flag $matched_flag requires a value: <$value_name>"
    hook_output_block "Flag $matched_flag requires a value: <$value_name>"
    exit 0
  fi

  log_debug "VALIDATE_FLAG_VALUE" "$matched_flag has value '${BASH_REMATCH[3]}' (valid)"
  return 0
}

# ============================================================================
# Validate flag requires another flag to be present
# Usage: validate_requires <args> <flag_pattern> <required_pattern>
# Returns: 0 if valid, exits with block if flag present without required
# ============================================================================
validate_requires() {
  local args="$1"
  local flag_pattern="$2"
  local required_pattern="$3"

  # Convert "or" syntax to regex
  local flag_regex="${flag_pattern// or /|}"
  local required_regex="${required_pattern// or /|}"

  # Check if flag is present
  if [[ ! "$args" =~ (^|[[:space:]])($flag_regex)([[:space:]]|$) ]]; then
    return 0  # Flag not present, nothing to check
  fi

  local matched_flag="${BASH_REMATCH[2]}"

  # Check if required is present
  if [[ ! "$args" =~ (^|[[:space:]])($required_regex)([[:space:]]|$) ]]; then
    log_error "Flag $matched_flag requires $required_pattern"
    hook_output_block "Flag $matched_flag requires $required_pattern to be present"
    exit 0
  fi

  log_debug "VALIDATE_REQUIRES" "$matched_flag requires $required_pattern (valid)"
  return 0
}

# ============================================================================
# Check if a flag is present in args
# Usage: has_flag <args> <flag_pattern>
# Pattern format: "-l or --last"
# Returns: 0 if present, 1 if not
# ============================================================================
has_flag() {
  local args="$1"
  local pattern="$2"

  local regex="${pattern// or /|}"
  if [[ "$args" =~ (^|[[:space:]])($regex)([[:space:]]|$) ]]; then
    return 0
  fi
  return 1
}

# ============================================================================
# Get value after a flag
# Usage: get_flag_value <args> <flag_pattern>
# Returns: The value via stdout, or empty if not found
# ============================================================================
get_flag_value() {
  local args="$1"
  local pattern="$2"

  local regex="${pattern// or /|}"
  local value_regex="(^|[[:space:]])($regex)[[:space:]]+([^[:space:]][^[:space:]]*)"

  if [[ "$args" =~ $value_regex ]]; then
    echo "${BASH_REMATCH[3]}"
  fi
}

# ============================================================================
# Get first positional argument (non-flag)
# Usage: get_positional_arg <args> [<index>]
# Returns: The positional argument via stdout, or empty if not found
# ============================================================================
get_positional_arg() {
  local args="$1"
  local index="${2:-0}"
  local current=0

  # Split args into array
  local -a parts
  read -ra parts <<< "$args"

  local skip_next=false
  for part in "${parts[@]}"; do
    if [[ "$skip_next" == "true" ]]; then
      skip_next=false
      continue
    fi

    # Skip flags and their values
    if [[ "$part" =~ ^- ]]; then
      # Check if this flag takes a value
      case "$part" in
        --worktree|--base|--files|--context|--resolve-level|--format|--session-path|-l|-a|-t|-m|-sc|-c|--since-commit|--single-commit)
          skip_next=true
          ;;
      esac
      continue
    fi

    # Found positional argument
    if [[ $current -eq $index ]]; then
      echo "$part"
      return 0
    fi
    ((current++))
  done
}

# ============================================================================
# Validate argument count (for + modifier)
# Usage: validate_min_args <args> <min_count> <arg_name>
# Returns: 0 if valid, exits with block if insufficient
# ============================================================================
validate_min_args() {
  local args="$1"
  local min_count="$2"
  local arg_name="$3"

  # Count positional arguments
  local count=0
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
        --worktree|--base|--files|--context|--resolve-level|--format|--session-path|-l|-a|-t|-m|-sc|-c|--since-commit|--single-commit)
          skip_next=true
          ;;
      esac
      continue
    fi

    ((count++))
  done

  if [[ $count -lt $min_count ]]; then
    log_error "Requires at least $min_count $arg_name, got $count"
    hook_output_block "Requires at least $min_count <$arg_name>, got $count"
    exit 0
  fi

  log_debug "VALIDATE_MIN_ARGS" "$count >= $min_count $arg_name (valid)"
  return 0
}
