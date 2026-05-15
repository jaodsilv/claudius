#!/bin/bash
# Retry helper for network-dependent commands (gh, git fetch).
#
# Usage:
#   source "$CLAUDE_PLUGIN_ROOT/scripts/lib/retry.sh"
#   retry_cmd <description> -- <command> [args...]
#
# Behavior:
#   - 2 attempts max (1 initial + 1 retry)
#   - Backoff: 1s before retry attempt
#   - 30s per-call timeout (uses `timeout` if available; otherwise plain run)
#   - Returns the exit code of the last attempt
#   - Stdout/stderr of the command are passed through unchanged
#
# Exit codes:
#   0   command succeeded on some attempt
#   124 timed out (all attempts)
#   *   non-zero from the underlying command on the final attempt

# Guard against double-sourcing
if [[ -n "${_RETRY_SH_SOURCED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
_RETRY_SH_SOURCED=1

readonly RETRY_TIMEOUT_SECS="${RETRY_TIMEOUT_SECS:-30}"
readonly RETRY_BACKOFF_FIRST="${RETRY_BACKOFF_FIRST:-1}"
readonly RETRY_BACKOFF_SECOND="${RETRY_BACKOFF_SECOND:-3}"
readonly RETRY_MAX_ATTEMPTS="${RETRY_MAX_ATTEMPTS:-2}"

# Run a command under a timeout, if `timeout` is available; otherwise fall back
# to running the command directly.
_retry_run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "${RETRY_TIMEOUT_SECS}s" "$@"
  else
    "$@"
  fi
}

# retry_cmd <description> -- <command> [args...]
# The `--` separator is required so descriptions cannot collide with command tokens.
retry_cmd() {
  local description="$1"
  shift

  if [[ "${1:-}" != "--" ]]; then
    echo "retry_cmd: expected '--' separator after description, got '${1:-<empty>}'" >&2
    return 2
  fi
  shift

  local attempt=1
  local rc=0
  local backoff

  while [[ $attempt -le $RETRY_MAX_ATTEMPTS ]]; do
    if [[ $attempt -gt 1 ]]; then
      if [[ $attempt -eq 2 ]]; then
        backoff="$RETRY_BACKOFF_FIRST"
      else
        backoff="$RETRY_BACKOFF_SECOND"
      fi
      if type -t log_warn >/dev/null 2>&1; then
        log_warn "retry [$description] attempt $attempt/$RETRY_MAX_ATTEMPTS after ${backoff}s (prev rc=$rc)"
      fi
      sleep "$backoff"
    fi

    _retry_run_with_timeout "$@"
    rc=$?

    if [[ $rc -eq 0 ]]; then
      return 0
    fi

    ((attempt++))
  done

  if type -t log_error >/dev/null 2>&1; then
    log_error "retry [$description] exhausted after $RETRY_MAX_ATTEMPTS attempts (rc=$rc)"
  fi
  return $rc
}

# Capture command output across retries. Echoes the command's combined stdout
# (stderr is discarded) on success. On failure, echoes nothing and returns the
# last exit code.
#
# Usage: out=$(retry_capture "<desc>" -- gh api ...)
retry_capture() {
  local description="$1"
  shift

  if [[ "${1:-}" != "--" ]]; then
    echo "retry_capture: expected '--' separator after description, got '${1:-<empty>}'" >&2
    return 2
  fi
  shift

  local attempt=1
  local rc=0
  local out=""
  local backoff

  while [[ $attempt -le $RETRY_MAX_ATTEMPTS ]]; do
    if [[ $attempt -gt 1 ]]; then
      if [[ $attempt -eq 2 ]]; then
        backoff="$RETRY_BACKOFF_FIRST"
      else
        backoff="$RETRY_BACKOFF_SECOND"
      fi
      if type -t log_warn >/dev/null 2>&1; then
        log_warn "retry_capture [$description] attempt $attempt/$RETRY_MAX_ATTEMPTS after ${backoff}s (prev rc=$rc)"
      fi
      sleep "$backoff"
    fi

    out=$(_retry_run_with_timeout "$@" 2>/dev/null)
    rc=$?

    if [[ $rc -eq 0 ]]; then
      printf '%s' "$out"
      return 0
    fi

    ((attempt++))
  done

  if type -t log_error >/dev/null 2>&1; then
    log_error "retry_capture [$description] exhausted after $RETRY_MAX_ATTEMPTS attempts (rc=$rc)"
  fi
  return $rc
}
