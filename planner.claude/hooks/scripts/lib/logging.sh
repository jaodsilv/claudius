#!/bin/bash
# Logging utility for planner hooks
# Simplified version - logs to stderr when debug enabled

PLANNER_DEBUG="${PLANNER_DEBUG:-0}"

log_init() { :; }

log_debug() {
  [[ "$PLANNER_DEBUG" != "1" ]] && return 0
  echo "[DEBUG] $1 = $2" >&2
}

log_info() {
  [[ "$PLANNER_DEBUG" != "1" ]] && return 0
  echo "[INFO] $1" >&2
}

log_error() {
  echo "[ERROR] $1" >&2
}

log_section() {
  [[ "$PLANNER_DEBUG" != "1" ]] && return 0
  echo "======== $1 ========" >&2
}

log_exit() { :; }
