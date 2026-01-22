#!/bin/bash
# Logging utility for gitx hooks
# Source this file to enable structured logging
#
# Usage:
#   source "${SCRIPT_DIR}/lib/logging.sh"
#   log_init "script-name"
#   log_debug "variable" "$value"
#   log_info "message"
#   log_warn "warning message"
#   log_error "error message"
#   log_section "Section Name"
#   log_json "label" "$json_data"
#
# Environment variables:
#   GITX_DEBUG=1        - Enable debug logging (default: off)
#   GITX_LOG_DIR        - Override log directory (default: $TMP/gitx-hooks)
#   GITX_LOG_VERBOSE=1  - Also print logs to stderr (default: off)

# ============================================================================
# Configuration - Easy to change
# ============================================================================
GITX_DEBUG="${GITX_DEBUG:-0}"
GITX_LOG_VERBOSE="${GITX_LOG_VERBOSE:-0}"
GITX_LOG_DIR="${GITX_LOG_DIR:-${TMP:-/tmp}/gitx-hooks}"

# ============================================================================
# Internal state
# ============================================================================
_LOG_FILE=""
_LOG_SCRIPT=""
_LOG_START_TIME=""

# ============================================================================
# Initialize logging for a script
# ============================================================================
log_init() {
  local script_name="$1"
  _LOG_SCRIPT="$script_name"
  _LOG_START_TIME=$(date +%s%3N 2>/dev/null || date +%s)

  if [[ "$GITX_DEBUG" != "1" ]]; then
    return 0
  fi

  # Create log directory
  mkdir -p "$GITX_LOG_DIR"

  # Create log file with timestamp
  local timestamp=$(date +"%Y%m%d-%H%M%S")
  local pid="$$"
  _LOG_FILE="${GITX_LOG_DIR}/${timestamp}-${script_name}-${pid}.log"

  # Write header
  {
    echo "================================================================================"
    echo "GITX Hook Log: $script_name"
    echo "================================================================================"
    echo "Timestamp:    $(date -Iseconds)"
    echo "PID:          $pid"
    echo "Log File:     $_LOG_FILE"
    echo "Working Dir:  $(pwd)"
    echo "================================================================================"
    echo ""
  } >> "$_LOG_FILE"

  # Log to stderr if verbose
  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$script_name] Logging to: $_LOG_FILE" >&2
  fi
}

# ============================================================================
# Log a debug message with variable name and value
# ============================================================================
log_debug() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local name="$1"
  local value="$2"
  local elapsed=$(_get_elapsed)

  local msg="[${elapsed}ms] DEBUG $name = \"$value\""
  echo "$msg" >> "$_LOG_FILE"

  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$_LOG_SCRIPT] $msg" >&2
  fi
}

# ============================================================================
# Log an info message
# ============================================================================
log_info() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local message="$1"
  local elapsed=$(_get_elapsed)

  local msg="[${elapsed}ms] INFO  $message"
  echo "$msg" >> "$_LOG_FILE"

  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$_LOG_SCRIPT] $msg" >&2
  fi
}

# ============================================================================
# Log a warning message
# ============================================================================
log_warn() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local message="$1"
  local elapsed=$(_get_elapsed)

  local msg="[${elapsed}ms] WARN  $message"
  echo "$msg" >> "$_LOG_FILE"

  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$_LOG_SCRIPT] $msg" >&2
  fi
}

# ============================================================================
# Log an error message
# ============================================================================
log_error() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local message="$1"
  local elapsed=$(_get_elapsed)

  local msg="[${elapsed}ms] ERROR $message"
  echo "$msg" >> "$_LOG_FILE"

  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$_LOG_SCRIPT] $msg" >&2
  fi
}

# ============================================================================
# Log a section header
# ============================================================================
log_section() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local title="$1"
  local elapsed=$(_get_elapsed)

  {
    echo ""
    echo "[${elapsed}ms] ======== $title ========"
  } >> "$_LOG_FILE"

  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$_LOG_SCRIPT] ======== $title ========" >&2
  fi
}

# ============================================================================
# Log JSON data (pretty-printed if jq available)
# ============================================================================
log_json() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local label="$1"
  local json="$2"
  local elapsed=$(_get_elapsed)

  {
    echo "[${elapsed}ms] JSON  $label:"
    if command -v jq &>/dev/null && [[ -n "$json" ]]; then
      echo "$json" | jq '.' 2>/dev/null || echo "$json"
    else
      echo "$json"
    fi
    echo ""
  } >> "$_LOG_FILE"
}

# ============================================================================
# Log command execution and result
# ============================================================================
log_cmd() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local cmd="$1"
  local result="$2"
  local exit_code="$3"
  local elapsed=$(_get_elapsed)

  {
    echo "[${elapsed}ms] CMD   $ $cmd"
    echo "         Exit: $exit_code"
    if [[ -n "$result" ]]; then
      echo "         Output: $result"
    fi
  } >> "$_LOG_FILE"
}

# ============================================================================
# Log script exit
# ============================================================================
log_exit() {
  [[ "$GITX_DEBUG" != "1" ]] && return 0
  local exit_code="$1"
  local reason="${2:-}"
  local elapsed=$(_get_elapsed)

  {
    echo ""
    echo "[${elapsed}ms] EXIT  code=$exit_code${reason:+ reason=\"$reason\"}"
    echo ""
    echo "================================================================================"
    echo "End of log - Total time: ${elapsed}ms"
    echo "================================================================================"
  } >> "$_LOG_FILE"

  if [[ "$GITX_LOG_VERBOSE" == "1" ]]; then
    echo "[gitx:$_LOG_SCRIPT] Exit $exit_code (${elapsed}ms)${reason:+ - $reason}" >&2
  fi
}

# ============================================================================
# Get elapsed time in milliseconds
# ============================================================================
_get_elapsed() {
  local now=$(date +%s%3N 2>/dev/null || date +%s)
  echo $((now - _LOG_START_TIME))
}

# ============================================================================
# Print log location (for user feedback)
# ============================================================================
log_location() {
  if [[ "$GITX_DEBUG" == "1" ]] && [[ -n "$_LOG_FILE" ]]; then
    echo "$_LOG_FILE"
  fi
}
