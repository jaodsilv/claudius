#!/bin/bash
# PreToolUse dispatcher for gitx skills
# Handles validation and setup when gitx skills are invoked via Skill tool
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export GITX_DEBUG=1          # Enable debug logging
# export GITX_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source logging
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
export HANDLERS_DIR="${SCRIPTS_DIR}/handlers"
LIBS_DIR="${SCRIPTS_DIR}/lib"
source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-helper.sh"
source "$LIBS_DIR/args-validator.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "pre-skill"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="PreToolUse"

init

# Dispatch to command-specific handler
log_section "Handler Dispatch"
log_info "Dispatching to handler: $COMMAND"

case "$COMMAND" in
  address-ci)
    log_info "Loading address-ci.sh"
    source "$HANDLERS_DIR/address-ci.sh"
    ;;
  address-review)
    log_info "Loading address-review.sh"
    source "$HANDLERS_DIR/address-review.sh"
    ;;
  commit-push)
    log_info "Loading commit-push-pre.sh"
    source "$HANDLERS_DIR/commit-push-pre.sh"
    ;;
  comment-to-issue|fix-issue)
    log_info "Loading pre-comment-to-issue.sh"
    source "$HANDLERS_DIR/pre-comment-to-issue.sh"
    ;;
  comment-to-pr)
    log_info "Loading comment-to-pr.sh"
    source "$HANDLERS_DIR/comment-to-pr.sh"
    ;;
  create-issue)
    log_info "Loading create-issue.sh"
    source "$HANDLERS_DIR/create-issue.sh"
    ;;
  ignore)
    log_info "Loading ignore.sh"
    source "$HANDLERS_DIR/ignore.sh"
    ;;
  merge-pr)
    log_info "Loading merge-pr.sh"
    source "$HANDLERS_DIR/merge-pr.sh"
    ;;
  merge)
    log_info "Loading merge.sh"
    source "$HANDLERS_DIR/merge.sh"
    ;;
  next-issue)
    log_info "Loading next-issue.sh"
    source "$HANDLERS_DIR/next-issue.sh"
    ;;
  next-turn)
    log_info "Loading next-turn.sh"
    source "$HANDLERS_DIR/next-turn.sh"
    ;;
  pr)
    log_info "Loading pr.sh"
    source "$HANDLERS_DIR/pr.sh"
    ;;
  update-pr)
    log_info "Loading pre-update-pr.sh"
    source "$HANDLERS_DIR/pre-update-pr.sh"
    ;;
  rebase)
    log_info "Loading rebase.sh"
    source "$HANDLERS_DIR/rebase.sh"
    ;;
  remove-branch)
    log_info "Loading remove-branch.sh"
    source "$HANDLERS_DIR/remove-branch.sh"
    ;;
  remove-worktree)
    log_info "Loading remove-worktree.sh"
    source "$HANDLERS_DIR/remove-worktree.sh"
    ;;
  review)
    log_info "Loading review.sh"
    source "$HANDLERS_DIR/review.sh"
    ;;
  refresh-metadata)
    log_info "Loading refresh-metadata.sh"
    source "$HANDLERS_DIR/refresh-metadata.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
