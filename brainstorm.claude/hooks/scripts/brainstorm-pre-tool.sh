#!/bin/bash
# PreToolUse dispatcher for brainstorm skills
# Validates arguments before skill execution
set -uo pipefail

SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
LIBS_DIR="${SCRIPTS_DIR}/lib"

# Plugin config (set BEFORE sourcing shared libs)
HOOK_PLUGIN_NAME="BRAINSTORM"
_PLUGIN_VALUE_FLAGS=(--depth --output-path --session-path --format)

source "$LIBS_DIR/logging.sh"
source "$LIBS_DIR/args-validator.sh"
source "$LIBS_DIR/hook-output.sh"
log_init "pre-tool"

export HOOK_EVENT_TYPE="PreToolUse"

# Read JSON input
INPUT=$(cat)
log_section "Input Processing"

CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
export CWD

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
