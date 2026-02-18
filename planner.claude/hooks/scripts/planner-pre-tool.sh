#!/bin/bash
# PreToolUse dispatcher for planner skills
# Validates arguments before skill execution
set -uo pipefail

SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
LIBS_DIR="${SCRIPTS_DIR}/lib"

# Plugin config (set BEFORE sourcing shared libs)
HOOK_PLUGIN_NAME="PLANNER"
_PLUGIN_VALUE_FLAGS=(--use-brainstorm --depth --output --mode --rounds --framework --architecture-path --goal --prioritization-path --requirements-path --roadmap-path --phases --horizon)

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-validator.sh"
log_init "pre-tool"

export HOOK_EVENT_TYPE="PreToolUse"

# Read JSON input
INPUT=$(cat)
log_section "Input Processing"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
if [[ "$TOOL_NAME" != "Skill" ]]; then
  exit 0
fi

SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
if [[ ! "$SKILL" =~ ^planner: ]]; then
  exit 0
fi

COMMAND="${SKILL#planner:}"
ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
log_debug "COMMAND" "$COMMAND"
log_debug "ARGS" "$ARGS"

export ARGS

HANDLERS_DIR="$SCRIPTS_DIR/handlers"

case "$COMMAND" in
  gather-requirements)
    source "$HANDLERS_DIR/gather-requirements.sh"
    ;;
  ideas)
    source "$HANDLERS_DIR/ideas.sh"
    ;;
  prioritize)
    source "$HANDLERS_DIR/prioritize.sh"
    ;;
  roadmap)
    source "$HANDLERS_DIR/roadmap.sh"
    ;;
  review-architecture|review-plan|review-prioritization|review-requirements|review-roadmap)
    source "$HANDLERS_DIR/review-common.sh"
    ;;
  *)
    exit 0
    ;;
esac
