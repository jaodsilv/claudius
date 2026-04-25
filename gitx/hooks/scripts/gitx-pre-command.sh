#!/bin/bash
# Main dispatcher for UserPromptSubmit hook
# Handles validation and setup for all /gitx:* commands
set -uo pipefail

# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
# export GITX_DEBUG=1          # Enable debug logging
# export GITX_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================

# Get script directory and source libraries
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
export HANDLERS_DIR="${SCRIPTS_DIR}/handlers"
LIBS_DIR="${SCRIPTS_DIR}/lib"

# Plugin config (set BEFORE sourcing shared libs)
export HOOK_PLUGIN_NAME="GITX"
export _PLUGIN_VALUE_FLAGS=(--worktree --base --files --context --resolve-level --format --session-path -l -a -t -m -sc -c --since-commit --single-commit --repo --pr)

# Read input and export CWD before logging init
INPUT=$(cat)
export CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-helper.sh"
source "$SCRIPTS_DIR/gitx-helpers.sh"
source "$LIBS_DIR/args-validator.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "pre-command"

# Set hook event type for output formatting
export HOOK_EVENT_TYPE="UserPromptSubmit"

init

# Dispatch to command-specific handler
log_section "Handler Dispatch"
log_info "Dispatching to handler: $COMMAND"

case "$COMMAND" in
  address-ci)
    log_info "Loading ci/address-ci.sh"
    source "$HANDLERS_DIR/ci/address-ci.sh"
    ;;
  address-review)
    log_info "Loading reviews/address-review.sh"
    source "$HANDLERS_DIR/reviews/address-review.sh"
    ;;
  commit-push)
    log_info "Loading commits/commit-push-pre.sh"
    source "$HANDLERS_DIR/commits/commit-push-pre.sh"
    ;;
  comment-to-issue|fix-issue)
    log_info "Loading issues/pre-comment-to-issue.sh"
    source "$HANDLERS_DIR/issues/pre-comment-to-issue.sh"
    ;;
  comment-to-pr)
    log_info "Loading prs/comment-to-pr.sh"
    source "$HANDLERS_DIR/prs/comment-to-pr.sh"
    ;;
  ignore)
    log_info "Loading workflow/ignore.sh"
    source "$HANDLERS_DIR/workflow/ignore.sh"
    ;;
  merge-pr)
    log_info "Loading prs/merge-pr.sh"
    source "$HANDLERS_DIR/prs/merge-pr.sh"
    ;;
  merge)
    log_info "Loading branches/merge.sh"
    source "$HANDLERS_DIR/branches/merge.sh"
    ;;
  next-issue)
    log_info "Loading issues/next-issue.sh"
    source "$HANDLERS_DIR/issues/next-issue.sh"
    ;;
  next-turn)
    log_info "Loading workflow/next-turn.sh"
    source "$HANDLERS_DIR/workflow/next-turn.sh"
    ;;
  pr)
    log_info "Loading prs/pr.sh"
    source "$HANDLERS_DIR/prs/pr.sh"
    ;;
  update-pr)
    log_info "Loading prs/pre-update-pr.sh"
    source "$HANDLERS_DIR/prs/pre-update-pr.sh"
    ;;
  rebase)
    log_info "Loading branches/rebase.sh"
    source "$HANDLERS_DIR/branches/rebase.sh"
    ;;
  remove-branch)
    log_info "Loading branches/remove-branch.sh"
    source "$HANDLERS_DIR/branches/remove-branch.sh"
    ;;
  remove-worktree)
    log_info "Loading worktrees/remove-worktree.sh"
    source "$HANDLERS_DIR/worktrees/remove-worktree.sh"
    ;;
  review)
    log_info "Loading reviews/review.sh"
    source "$HANDLERS_DIR/reviews/review.sh"
    ;;
  refresh-metadata)
    log_info "Loading metadata/refresh-metadata.sh"
    source "$HANDLERS_DIR/metadata/refresh-metadata.sh"
    ;;
  parse-issue-reference)
    log_info "Loading issues/parse-issue-reference.sh"
    source "$HANDLERS_DIR/issues/parse-issue-reference.sh"
    ;;
  *)
    log_info "Unknown command '$COMMAND', passing through"
    log_exit 0 "unknown command - pass through"
    exit 0
    ;;
esac
