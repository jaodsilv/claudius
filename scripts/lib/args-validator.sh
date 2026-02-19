#!/bin/bash
# Shared library for validating skill arguments
# Provides reusable validation primitives following argument-hint notation rules
# Enhanced with named parameters, greedy mode, quote-aware parsing, negative indexing, and XML tag support
#
# Caller MUST set _PLUGIN_VALUE_FLAGS array before sourcing (or leave empty)
#
# Usage:
#   _PLUGIN_VALUE_FLAGS=(--worktree --base --files)
#   source "$SCRIPTS_DIR/lib/args-validator.sh"
#   validate_required_arg "description" "$value"
#   validate_one_of "mode" "$mode" "squash" "merge" "rebase"
#   validate_mutually_exclusive "$args" "-l or --last" "-c or --single-commit" "-sc or --since-commit"
#   validate_flag_value "$args" "-sc or --since-commit" "commit hash"
#   get_xml_value "$args" "tag-name"
#
# XML Tag Support:
#   Arguments can be provided in XML-style tags alongside CLI flags:
#   <tag-name>value</tag-name>
#   Tags support multiline content and nested tags are preserved as raw content.

# Source hook-output for blocking
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}"
source "$SCRIPTS_DIR/lib/hook-output.sh"

# ============================================================================
# Plugin-specific flags that take values
# Caller sets _PLUGIN_VALUE_FLAGS before sourcing; default to empty
# ============================================================================
if [[ -z "${_PLUGIN_VALUE_FLAGS+x}" ]]; then
  _PLUGIN_VALUE_FLAGS=()
fi

# ============================================================================
# Strip outer code fence from content (```lang ... ```)
# Usage: _strip_code_fence <content>
# Returns: Content without code fence wrapper, or original if no fence found
# ============================================================================
_strip_code_fence() {
  local content="$1"
  [[ -z "$content" ]] && return 0
  [[ "$content" != *$'\n'* ]] && { echo "$content"; return; }

  local first_line="${content%%$'\n'*}"
  local last_line="${content##*$'\n'}"

  if [[ "$first_line" =~ ^'```'[a-zA-Z0-9]*$ ]] && [[ "$last_line" == '```' ]]; then
    content="${content#*$'\n'}"   # remove first line
    content="${content%$'\n'*}"   # remove last line
  fi
  echo "$content"
}

# ============================================================================
# Extract XML tag content from args string
# Usage: get_xml_value <args> <tag-name>
# Returns: Content between <tag-name> and </tag-name>, or empty if not found
# Note: Only extracts top-level tags; nested tags with same name won't be found
# ============================================================================
get_xml_value() {
  local args="$1"
  local tag_name="$2"

  # Build regex pattern for the tag
  # Match <tag-name> followed by optional newline, content, then </tag-name>
  local open_tag="<${tag_name}>"
  local close_tag="</${tag_name}>"

  # Check if tag exists
  if [[ "$args" != *"$open_tag"* ]] || [[ "$args" != *"$close_tag"* ]]; then
    return 0
  fi

  # Extract content between tags
  # Use parameter expansion to find positions
  local after_open="${args#*$open_tag}"
  local content="${after_open%%$close_tag*}"

  # Trim leading newline if present (allows <tag>\ncontent\n</tag> format)
  if [[ "${content:0:1}" == $'\n' ]]; then
    content="${content:1}"
  fi
  # Trim trailing newline if present
  if [[ "${content: -1}" == $'\n' ]]; then
    content="${content%$'\n'}"
  fi

  # Strip outer code fence if present
  content=$(_strip_code_fence "$content")

  echo "$content"
}

# ============================================================================
# Check if an XML tag exists in args
# Usage: has_xml_tag <args> <tag-name>
# Returns: 0 if tag exists, 1 if not
# ============================================================================
has_xml_tag() {
  local args="$1"
  local tag_name="$2"
  local open_tag="<${tag_name}>"
  local close_tag="</${tag_name}>"

  [[ "$args" == *"$open_tag"* ]] && [[ "$args" == *"$close_tag"* ]]
}

# ============================================================================
# Strip all XML tags from args string for tokenization
# Usage: _strip_xml_tags <args>
# Returns: Args string with all XML tag blocks removed
# ============================================================================
_strip_xml_tags() {
  local args="$1"
  local result="$args"

  # Find and remove all XML tag patterns: <tag>...</tag>
  # Process iteratively to handle multiple tags
  while [[ "$result" =~ '<'([a-zA-Z][a-zA-Z0-9_-]*)'>' ]]; do
    local tag_name="${BASH_REMATCH[1]}"
    local open_tag="<${tag_name}>"
    local close_tag="</${tag_name}>"

    # Check if closing tag exists
    if [[ "$result" == *"$close_tag"* ]]; then
      # Remove the entire tag block
      local before="${result%%$open_tag*}"
      local after_open="${result#*$open_tag}"
      local after="${after_open#*$close_tag}"
      result="${before}${after}"
    else
      # No closing tag, stop processing (malformed)
      break
    fi
  done

  echo "$result"
}

# ============================================================================
# Convert tag name to flag name (tag-name -> --tag-name)
# Usage: _tag_to_flag <tag-name>
# ============================================================================
_tag_to_flag() {
  echo "--$1"
}

# ============================================================================
# Convert flag name to tag name (--flag-name or -f -> flag-name or f)
# Usage: _flag_to_tag <flag>
# ============================================================================
_flag_to_tag() {
  local flag="$1"
  # Remove leading dashes
  flag="${flag#--}"
  flag="${flag#-}"
  echo "$flag"
}

# ============================================================================
# Tokenize args string respecting quoted values
# Usage: _tokenize_args <args>
# Outputs: One token per line with format: TYPE:VALUE
#          TYPE is Q (quoted) or U (unquoted)
# Note: XML tags are stripped before tokenization
# ============================================================================
_tokenize_args() {
  local args="$1"

  # Strip XML tags before tokenizing
  args=$(_strip_xml_tags "$args")

  local -a tokens=()
  local current=""
  local in_quote=false
  local escaped=false
  local i=0
  local len=${#args}

  while [[ $i -lt $len ]]; do
    local char="${args:$i:1}"

    if [[ "$escaped" == "true" ]]; then
      current+="$char"
      escaped=false
    elif [[ "$char" == "\\" ]]; then
      escaped=true
      current+="$char"
    elif [[ "$char" == '"' ]]; then
      if [[ "$in_quote" == "true" ]]; then
        # End of quoted string
        tokens+=("Q:$current")
        current=""
        in_quote=false
      else
        # Start of quoted string
        if [[ -n "$current" ]]; then
          tokens+=("U:$current")
          current=""
        fi
        in_quote=true
      fi
    elif [[ "$char" == " " || "$char" == $'\t' || "$char" == $'\n' ]]; then
      if [[ "$in_quote" == "true" ]]; then
        current+="$char"
      elif [[ -n "$current" ]]; then
        tokens+=("U:$current")
        current=""
      fi
    else
      current+="$char"
    fi
    ((i++))
  done

  # Handle remaining content
  if [[ -n "$current" ]]; then
    if [[ "$in_quote" == "true" ]]; then
      tokens+=("Q:$current")
    else
      tokens+=("U:$current")
    fi
  fi

  # Output tokens
  for token in "${tokens[@]}"; do
    echo "$token"
  done
}

# ============================================================================
# Normalize flag pattern - ensure it starts with --
# Usage: _normalize_flag <pattern>
# ============================================================================
_normalize_flag() {
  local pattern="$1"
  # If pattern contains " or " (alternative syntax), return as-is
  if [[ "$pattern" == *" or "* ]]; then
    echo "$pattern"
    return
  fi
  # If already starts with -, return as-is
  if [[ "$pattern" == -* ]]; then
    echo "$pattern"
    return
  fi
  # Add -- prefix
  echo "--$pattern"
}

# ============================================================================
# Check if a value is a flag (starts with -)
# ============================================================================
_is_flag() {
  [[ "$1" == -* ]]
}

# ============================================================================
# Check if a flag takes a value
# ============================================================================
_flag_takes_value() {
  local flag="$1"
  for vflag in "${_PLUGIN_VALUE_FLAGS[@]}"; do
    if [[ "$flag" == "$vflag" ]]; then
      return 0
    fi
  done
  return 1
}

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
    if has_flag "$args" "$pattern"; then
      found+=("$pattern")
      found_names+=("$pattern")
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

  # CLI flag check (existing regex logic)
  if [[ "$args" =~ (^|[[:space:]])($regex)([[:space:]]|$) ]]; then
    local matched_flag="${BASH_REMATCH[2]}"
    local value_regex="(^|[[:space:]])($regex)[[:space:]]+([^[:space:]][^[:space:]]*)"
    if [[ ! "$args" =~ $value_regex ]] || [[ "${BASH_REMATCH[3]}" == --* ]]; then
      log_error "Flag $matched_flag requires a value: <$value_name>"
      hook_output_block "Flag $matched_flag requires a value: <$value_name>"
      exit 0
    fi
    log_debug "VALIDATE_FLAG_VALUE" "$matched_flag has value '${BASH_REMATCH[3]}' (valid)"
    return 0
  fi

  # XML tag check — presence means value exists
  local tag_pattern="${pattern// or / }"
  for flag in $tag_pattern; do
    local tag_name="$(_flag_to_tag "$flag")"
    if has_xml_tag "$args" "$tag_name"; then
      log_debug "VALIDATE_FLAG_VALUE" "<$tag_name> tag present (valid)"
      return 0
    fi
  done

  log_debug "VALIDATE_FLAG_VALUE" "$pattern not present (skip)"
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

  if ! has_flag "$args" "$flag_pattern"; then
    return 0
  fi
  if ! has_flag "$args" "$required_pattern"; then
    log_error "$flag_pattern requires $required_pattern"
    hook_output_block "$flag_pattern requires $required_pattern to be present"
    exit 0
  fi

  log_debug "VALIDATE_REQUIRES" "$flag_pattern requires $required_pattern (valid)"
  return 0
}

# ============================================================================
# Check if a flag is present in args (also checks for XML tags)
# Usage: has_flag <args> <flag_pattern>
# Pattern format: "-l or --last"
# Returns: 0 if present (as flag or XML tag), 1 if not
# ============================================================================
has_flag() {
  local args="$1"
  local pattern="$2"

  # Check for CLI flag
  local regex="${pattern// or /|}"
  if [[ "$args" =~ (^|[[:space:]])($regex)([[:space:]]|$) ]]; then
    return 0
  fi

  # Check for XML tag equivalent
  local tag_pattern="${pattern// or / }"
  for flag in $tag_pattern; do
    local tag_name="$(_flag_to_tag "$flag")"
    if has_xml_tag "$args" "$tag_name"; then
      return 0
    fi
  done

  return 1
}

# ============================================================================
# Get value after a flag with enhanced options
# Usage: get_flag_value <args> <flag_pattern> [options]
# Options:
#   --default <value>  Default if flag not found
#   --pos <index>      Positional fallback index
#   --greedy           Collect all values until next flag
#   --required         Exit with error if not found
# Precedence: Flag value = XML tag value > Positional fallback > Default value
# Note: If both flag AND XML tag are present for same argument, validation fails
# ============================================================================
get_flag_value() {
  local args="$1"
  local pattern="$2"
  shift 2

  # Parse named parameters
  local default_value=""
  local pos_fallback=""
  local greedy=false
  local required=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default)
        default_value="$2"
        shift 2
        ;;
      --pos)
        pos_fallback="$2"
        shift 2
        ;;
      --greedy)
        greedy=true
        shift
        ;;
      --required)
        required=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  # Normalize flag pattern
  pattern=$(_normalize_flag "$pattern")

  # Convert "or" syntax to regex for matching
  local regex="${pattern// or /|}"

  # Extract possible tag names from pattern (e.g., "--name or -n" -> "name", "n")
  local -a tag_names=()
  local tag_pattern="${pattern// or / }"
  for flag in $tag_pattern; do
    tag_names+=("$(_flag_to_tag "$flag")")
  done

  # Check for XML tag values
  local xml_value=""
  local xml_tag_found=""
  for tag_name in "${tag_names[@]}"; do
    if has_xml_tag "$args" "$tag_name"; then
      xml_value=$(get_xml_value "$args" "$tag_name")
      xml_tag_found="$tag_name"
      break
    fi
  done

  # Tokenize args (XML tags are stripped)
  local -a tokens=()
  local -a token_types=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      token_types+=("${line%%:*}")
      tokens+=("${line#*:}")
    fi
  done < <(_tokenize_args "$args")

  local result=""
  local found=false
  local i=0

  # Find the flag and extract value(s)
  while [[ $i -lt ${#tokens[@]} ]]; do
    local token="${tokens[$i]}"
    local ttype="${token_types[$i]}"

    # Check if this token matches our flag pattern
    if [[ "$ttype" == "U" ]] && [[ "$token" =~ ^($regex)$ ]]; then
      found=true
      ((i++))

      if [[ "$greedy" == "true" ]]; then
        # Collect all values until next flag or end
        local -a values=()
        while [[ $i -lt ${#tokens[@]} ]]; do
          local val="${tokens[$i]}"
          local vtype="${token_types[$i]}"
          if [[ "$vtype" == "U" ]] && _is_flag "$val"; then
            break
          fi
          values+=("$val")
          ((i++))
        done
        result="${values[*]}"
      else
        # Get single value
        if [[ $i -lt ${#tokens[@]} ]]; then
          result="${tokens[$i]}"
        fi
      fi
      break
    fi
    ((i++))
  done

  # Check for conflict: both flag AND XML tag present
  if [[ "$found" == "true" && -n "$xml_tag_found" ]]; then
    log_error "Argument conflict: both flag $pattern and XML tag <$xml_tag_found> provided"
    hook_output_block "Argument conflict: cannot use both $pattern flag and <$xml_tag_found> tag for the same argument"
    exit 0
  fi

  # Use XML value if flag not found but XML tag exists
  if [[ "$found" == "false" && -n "$xml_tag_found" ]]; then
    result="$xml_value"
    found=true
  fi

  # If flag not found, try positional fallback
  if [[ "$found" == "false" && -n "$pos_fallback" ]]; then
    if [[ "$greedy" == "true" ]]; then
      result=$(get_positional_arg "$args" --greedy "$pos_fallback")
    else
      result=$(get_positional_arg "$args" "$pos_fallback")
    fi
  fi

  # If still empty, use default
  if [[ -z "$result" && -n "$default_value" ]]; then
    result="$default_value"
  fi

  # Handle required validation
  if [[ "$required" == "true" && -z "$result" ]]; then
    validate_required_arg "$pattern" ""
  fi

  echo "$result"
}

# ============================================================================
# Get positional argument with enhanced options
# Usage: get_positional_arg <args> [index] [options]
#        get_positional_arg <args> --greedy <index> [options]
# Options:
#   --greedy <index>   Collect multiple tokens (forward if positive, backward if negative)
#   --default <value>  Default if not found
#   --required         Exit with error if not found
# Negative index: -1 = last, -2 = second to last, etc.
# ============================================================================
get_positional_arg() {
  local args="$1"
  shift

  # Parse parameters
  local index=0
  local greedy=false
  local default_value=""
  local required=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --greedy)
        greedy=true
        if [[ -n "$2" && "$2" != --* ]]; then
          index="$2"
          shift
        fi
        shift
        ;;
      --default)
        default_value="$2"
        shift 2
        ;;
      --required)
        required=true
        shift
        ;;
      -*)
        # Could be negative index
        if [[ "$1" =~ ^-[0-9]+$ ]]; then
          index="$1"
          shift
        else
          shift
        fi
        ;;
      *)
        # Numeric index
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          index="$1"
        fi
        shift
        ;;
    esac
  done

  # Tokenize args
  local -a tokens=()
  local -a token_types=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      token_types+=("${line%%:*}")
      tokens+=("${line#*:}")
    fi
  done < <(_tokenize_args "$args")

  # Build array of positional arguments (skip flags and their values)
  # Also track boundary markers: F=flag boundary before this position, Q=quoted, U=unquoted
  local -a positionals=()
  local -a pos_types=()
  local i=0
  local skip_next=false
  local flag_seen=false

  while [[ $i -lt ${#tokens[@]} ]]; do
    local token="${tokens[$i]}"
    local ttype="${token_types[$i]}"

    if [[ "$skip_next" == "true" ]]; then
      skip_next=false
      ((i++))
      continue
    fi

    if [[ "$ttype" == "U" ]] && _is_flag "$token"; then
      if _flag_takes_value "$token"; then
        skip_next=true
      fi
      flag_seen=true
      ((i++))
      continue
    fi

    positionals+=("$token")
    # Mark with F if a flag was seen before this positional (boundary marker)
    if [[ "$flag_seen" == "true" ]]; then
      pos_types+=("F$ttype")
      flag_seen=false
    else
      pos_types+=("$ttype")
    fi
    ((i++))
  done

  local total=${#positionals[@]}
  local result=""

  # Handle negative index
  local actual_index=$index
  if [[ $index -lt 0 ]]; then
    actual_index=$((total + index))
  fi

  if [[ "$greedy" == "true" ]]; then
    if [[ $index -lt 0 ]]; then
      # Greedy backward: collect from actual_index backwards to start or boundary
      local -a collected=()
      local j=$actual_index
      while [[ $j -ge 0 ]]; do
        local ptype="${pos_types[$j]}"
        collected=("${positionals[$j]}" "${collected[@]}")
        # Stop if we hit a quoted boundary or flag boundary before our starting point
        if [[ $j -lt $actual_index && ("$ptype" == "Q" || "$ptype" == "FQ" || "$ptype" == "FU") ]]; then
          break
        fi
        ((j--))
      done

      result="${collected[*]}"
    else
      # Greedy forward: collect from position until next boundary (quoted or flag) or end
      local -a collected=()
      local j=$actual_index
      local started=false

      while [[ $j -lt $total ]]; do
        local ptype="${pos_types[$j]}"

        # Stop at boundaries (but include starting position even if it's a boundary)
        if [[ "$started" == "true" ]]; then
          # Check for flag boundary (F prefix) or quoted boundary
          if [[ "$ptype" == F* || "$ptype" == "Q" ]]; then
            break
          fi
        fi

        collected+=("${positionals[$j]}")
        started=true

        # If this was a quoted token, it's self-contained
        if [[ "$ptype" == "Q" || "$ptype" == "FQ" ]]; then
          break
        fi

        ((j++))
      done

      result="${collected[*]}"
    fi
  else
    # Non-greedy: return single positional
    if [[ $actual_index -ge 0 && $actual_index -lt $total ]]; then
      result="${positionals[$actual_index]}"
    fi
  fi

  # Apply default if empty
  if [[ -z "$result" && -n "$default_value" ]]; then
    result="$default_value"
  fi

  # Handle required validation
  if [[ "$required" == "true" && -z "$result" ]]; then
    validate_required_arg "positional argument $index" ""
  fi

  echo "$result"
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

  # Count positional arguments using tokenizer
  local -a tokens=()
  local -a token_types=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      token_types+=("${line%%:*}")
      tokens+=("${line#*:}")
    fi
  done < <(_tokenize_args "$args")

  local count=0
  local i=0
  local skip_next=false

  while [[ $i -lt ${#tokens[@]} ]]; do
    local token="${tokens[$i]}"
    local ttype="${token_types[$i]}"

    if [[ "$skip_next" == "true" ]]; then
      skip_next=false
      ((i++))
      continue
    fi

    if [[ "$ttype" == "U" ]] && _is_flag "$token"; then
      if _flag_takes_value "$token"; then
        skip_next=true
      fi
      ((i++))
      continue
    fi

    ((count++))
    ((i++))
  done

  if [[ $count -lt $min_count ]]; then
    log_error "Requires at least $min_count $arg_name, got $count"
    hook_output_block "Requires at least $min_count <$arg_name>, got $count"
    exit 0
  fi

  log_debug "VALIDATE_MIN_ARGS" "$count >= $min_count $arg_name (valid)"
  return 0
}
