#!/bin/bash
# PreToolUse dispatcher for brainstorm skills
# Validates arguments before skill execution
set -uo pipefail

SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/args-validator.sh"
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
if [[ ! "$SKILL" =~ ^brainstorm: ]]; then
  exit 0
fi

COMMAND="${SKILL#brainstorm:}"
ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
log_debug "COMMAND" "$COMMAND"
log_debug "ARGS" "$ARGS"

export ARGS

HANDLERS_DIR="$SCRIPTS_DIR/handlers"

case "$COMMAND" in
  start)
    source "$HANDLERS_DIR/start.sh"
    ;;
  continue)
    source "$HANDLERS_DIR/continue.sh"
    ;;
  export)
    source "$HANDLERS_DIR/export.sh"
    ;;
  *)
    exit 0
    ;;
esac
