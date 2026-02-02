#!/bin/bash
# Logging utility for brainstorm hooks
# Simplified version - logs to stderr when debug enabled

BRAINSTORM_DEBUG="${BRAINSTORM_DEBUG:-0}"

log_init() { :; }

log_debug() {
  [[ "$BRAINSTORM_DEBUG" != "1" ]] && return 0
  echo "[DEBUG] $1 = $2" >&2
}

log_info() {
  [[ "$BRAINSTORM_DEBUG" != "1" ]] && return 0
  echo "[INFO] $1" >&2
}

log_error() {
  echo "[ERROR] $1" >&2
}

log_section() {
  [[ "$BRAINSTORM_DEBUG" != "1" ]] && return 0
  echo "======== $1 ========" >&2
}

log_exit() { :; }
