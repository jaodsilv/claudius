#!/bin/bash
# PreToolUse dispatcher for gitx:ci:* agents
# Injects context (failure logs, analyses, plans) into agent prompts
# Called from gitx-pre-task.sh when task targets a gitx:ci:* agent

set -uo pipefail

SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"
source "$SCRIPTS_DIR/lib/args-validator.sh"
log_init "ci-pre-tool"
export HOOK_EVENT_TYPE="PreToolUse"

# Arguments from gitx-pre-task.sh
AGENT_NAME="$1"
RAW_INPUT="$2"

TOOL_INPUT=$(echo "$RAW_INPUT" | jq -r '.tool_input // {}')
PROMPT=$(echo "$TOOL_INPUT" | jq -r '.prompt // ""')

log_section "CI Pre-Tool Dispatch"
log_debug "AGENT" "$AGENT_NAME"

# Extract model for inject_or_read decisions (default: sonnet)
_AGENT_MODEL=$(echo "$RAW_INPUT" | jq -r '.tool_input.model // "sonnet"')
log_debug "AGENT_MODEL" "$_AGENT_MODEL"

# Extract agent suffix: gitx:ci:failure-analyzer -> failure-analyzer
AGENT_SUFFIX="${AGENT_NAME#gitx:ci:}"
log_debug "AGENT_SUFFIX" "$AGENT_SUFFIX"

# Parse worktree from prompt
WORKTREE=$(get_xml_value "$PROMPT" "worktree")
if [[ -z "$WORKTREE" ]]; then
  log_error "No <worktree> found in prompt"
  hook_output_block "Missing <worktree> in agent prompt"
  exit 0
fi
log_debug "WORKTREE" "$WORKTREE"

CI_DIR="$WORKTREE/.thoughts/pr/ci"

case "$AGENT_SUFFIX" in
  # ── failure-analyzer ─────────────────────────────────────────────────
  failure-analyzer)
    CHECK_ID=$(get_xml_value "$PROMPT" "check-id")
    if [[ -z "$CHECK_ID" ]]; then
      log_error "No <check-id> found in prompt"
      hook_output_block "Missing <check-id> in agent prompt"
      exit 0
    fi
    log_debug "CHECK_ID" "$CHECK_ID"

    LOG_FILE="$CI_DIR/failing-check-${CHECK_ID}.log"
    if [[ ! -f "$LOG_FILE" ]]; then
      log_error "Log file not found: $LOG_FILE"
      hook_output_block "Failure log not found: failing-check-${CHECK_ID}.log"
      exit 0
    fi

    log_info "Injecting failure log"
    LOG_CONTENT=$(inject_or_read "$LOG_FILE" "failure-log" "$_AGENT_MODEL")
    hook_output_context "$LOG_CONTENT"
    ;;

  # ── analyses-merger (orchestrator) ───────────────────────────────────
  analyses-merger)
    CHECK_IDS=$(get_xml_value "$PROMPT" "check-ids")
    if [[ -z "$CHECK_IDS" ]]; then
      log_error "No <check-ids> found in prompt"
      hook_output_block "Missing <check-ids> in agent prompt"
      exit 0
    fi
    log_debug "CHECK_IDS" "$CHECK_IDS"

    # Count IDs
    read -ra ID_ARRAY <<< "$CHECK_IDS"
    NUM_IDS=${#ID_ARRAY[@]}
    log_debug "NUM_IDS" "$NUM_IDS"

    if [[ "$NUM_IDS" -eq 1 ]]; then
      # Single ID: copy file directly as merged analysis, block agent
      SINGLE_ID="${ID_ARRAY[0]}"
      SRC="$CI_DIR/analyses/${SINGLE_ID}.md"
      if [[ ! -f "$SRC" ]]; then
        log_error "Analysis file not found: $SRC"
        hook_output_block "Analysis file not found for check $SINGLE_ID"
        exit 0
      fi
      cp "$SRC" "$CI_DIR/analyses/merged-analysis.md"
      log_info "Single check - copied $SINGLE_ID.md to merged-analysis.md"
      hook_output_block "Single check detected. Analysis already available as merged-analysis.md. <merged-id>${SINGLE_ID}</merged-id>"
      exit 0
    fi

    # Multiple IDs: generate processing order via Python helper
    PROCESSING_ORDER=$(python3 "$SCRIPTS_DIR/handlers/ci-merge-tree.py" ${CHECK_IDS})
    if [[ $? -ne 0 ]] || [[ -z "$PROCESSING_ORDER" ]]; then
      log_error "ci-merge-tree.py failed"
      hook_output_block "Failed to generate merge tree processing order"
      exit 0
    fi
    log_info "Injecting processing order"
    hook_output_context "$PROCESSING_ORDER"
    ;;

  # ── analysis-merger (single pair) ────────────────────────────────────
  analysis-merger)
    MERGE_ID=$(get_xml_value "$PROMPT" "id")
    INPUT1=$(get_xml_value "$PROMPT" "input1")
    INPUT2=$(get_xml_value "$PROMPT" "input2")

    if [[ -z "$MERGE_ID" ]] || [[ -z "$INPUT1" ]] || [[ -z "$INPUT2" ]]; then
      log_error "Missing <id>, <input1>, or <input2> in prompt"
      hook_output_block "Missing required tags: <id>, <input1>, <input2>"
      exit 0
    fi
    log_debug "MERGE" "$INPUT1 + $INPUT2 -> $MERGE_ID"

    FILE1="$CI_DIR/analyses/${INPUT1}.md"
    FILE2="$CI_DIR/analyses/${INPUT2}.md"

    if [[ ! -f "$FILE1" ]]; then
      log_error "Analysis file not found: $FILE1"
      hook_output_block "Analysis file not found: ${INPUT1}.md"
      exit 0
    fi
    if [[ ! -f "$FILE2" ]]; then
      log_error "Analysis file not found: $FILE2"
      hook_output_block "Analysis file not found: ${INPUT2}.md"
      exit 0
    fi

    log_info "Injecting two analyses for merge"
    CONTENT1=$(inject_or_read "$FILE1" "analysis1" "$_AGENT_MODEL")
    CONTENT2=$(inject_or_read "$FILE2" "analysis2" "$_AGENT_MODEL")
    hook_output_context "${CONTENT1}
${CONTENT2}"
    ;;

  # ── analysis-splitter ────────────────────────────────────────────────
  analysis-splitter)
    ANALYSIS_ID=$(get_xml_value "$PROMPT" "analysis-id")
    if [[ -z "$ANALYSIS_ID" ]]; then
      log_error "No <analysis-id> found in prompt"
      hook_output_block "Missing <analysis-id> in agent prompt"
      exit 0
    fi
    log_debug "ANALYSIS_ID" "$ANALYSIS_ID"

    ANALYSIS_FILE="$CI_DIR/analyses/${ANALYSIS_ID}.md"
    if [[ ! -f "$ANALYSIS_FILE" ]]; then
      log_error "Analysis file not found: $ANALYSIS_FILE"
      hook_output_block "Analysis file not found: ${ANALYSIS_ID}.md"
      exit 0
    fi

    log_info "Injecting analysis for splitting"
    ANALYSIS_CONTENT=$(inject_or_read "$ANALYSIS_FILE" "analysis" "$_AGENT_MODEL")
    hook_output_context "$ANALYSIS_CONTENT"
    ;;

  # ── fix-planner ──────────────────────────────────────────────────────
  fix-planner)
    TASK_ID=$(get_xml_value "$PROMPT" "task-id")
    if [[ -z "$TASK_ID" ]]; then
      log_error "No <task-id> found in prompt"
      hook_output_block "Missing <task-id> in agent prompt"
      exit 0
    fi
    log_debug "TASK_ID" "$TASK_ID"

    TASK_FILE="$CI_DIR/analyses/task-${TASK_ID}.md"
    if [[ ! -f "$TASK_FILE" ]]; then
      log_error "Task analysis file not found: $TASK_FILE"
      hook_output_block "Task analysis file not found: task-${TASK_ID}.md"
      exit 0
    fi

    log_info "Injecting task analysis for planning"
    TASK_CONTENT=$(inject_or_read "$TASK_FILE" "analysis" "$_AGENT_MODEL")
    hook_output_context "$TASK_CONTENT"
    ;;

  # ── fixer ────────────────────────────────────────────────────────────
  fixer)
    TASK_ID=$(get_xml_value "$PROMPT" "task-id")
    if [[ -z "$TASK_ID" ]]; then
      log_error "No <task-id> found in prompt"
      hook_output_block "Missing <task-id> in agent prompt"
      exit 0
    fi
    log_debug "TASK_ID" "$TASK_ID"

    PLAN_FILE="$CI_DIR/plan/${TASK_ID}.md"
    if [[ ! -f "$PLAN_FILE" ]]; then
      log_error "Plan file not found: $PLAN_FILE"
      hook_output_block "Plan file not found: plan/${TASK_ID}.md"
      exit 0
    fi

    log_info "Injecting fix plan"
    PLAN_CONTENT=$(inject_or_read "$PLAN_FILE" "plan" "$_AGENT_MODEL")
    hook_output_context "$PLAN_CONTENT"
    ;;

  # ── unknown agent ────────────────────────────────────────────────────
  *)
    log_info "No context injection for CI agent: $AGENT_SUFFIX"
    log_exit 0 "pass through"
    exit 0
    ;;
esac

log_exit 0 "context injected"
exit 0
