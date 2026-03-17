#!/bin/bash
# PreToolUse router for commit-push workflows
# Routes to appropriate handler based on skill/tool being called

set -uo pipefail

# Get script directory and source logging
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"
log_init "commit-push-pretool"

# Set hook event type
export HOOK_EVENT_TYPE="PreToolUse"

# Read JSON input
INPUT=$(cat)
log_section "Input Processing"
log_json "stdin_input" "$INPUT"

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

log_debug "TOOL_NAME" "$TOOL_NAME"
log_json "TOOL_INPUT" "$TOOL_INPUT"

case "$TOOL_NAME" in
  Skill)
    # Check which skill is being called
    SKILL_NAME=$(echo "$TOOL_INPUT" | jq -r '.skill // ""')
    SKILL_ARGS=$(echo "$TOOL_INPUT" | jq -r '.args // ""')

    log_debug "SKILL_NAME" "$SKILL_NAME"
    log_debug "SKILL_ARGS" "$SKILL_ARGS"

    case "$SKILL_NAME" in
      gitx:committing-conventionally)
        # Inject diffs for commit message generation
        log_info "Routing to inject-diff handler"
        bash "$SCRIPTS_DIR/handlers/commit-push-inject-diff.sh" <<< "$INPUT"
        exit $?
        ;;

      *)
        log_info "Unknown skill: $SKILL_NAME - pass through"
        log_exit 0 "pass through"
        exit 0
        ;;
    esac
    ;;

  Task)
    # Agent call - may need to inject diffs
    AGENT_TYPE=$(echo "$TOOL_INPUT" | jq -r '.subagent_type // ""')
    log_debug "AGENT_TYPE" "$AGENT_TYPE"

    case "$AGENT_TYPE" in
      gitx:commit:file-selector|gitx:commit:change-grouper|gitx:commit:commit-writer)
        # Inject diffs for file selection/grouping
        log_info "Routing to inject-diff handler for agent"
        bash "$SCRIPTS_DIR/handlers/commit-push-inject-diff.sh" <<< "$INPUT"
        exit $?
        ;;

      *)
        log_info "Unknown agent type: $AGENT_TYPE - pass through"
        log_exit 0 "pass through"
        exit 0
        ;;
    esac
    ;;

  *)
    # Unknown tool, pass through
    log_info "Unknown tool: $TOOL_NAME - pass through"
    log_exit 0 "pass through"
    exit 0
    ;;
esac
