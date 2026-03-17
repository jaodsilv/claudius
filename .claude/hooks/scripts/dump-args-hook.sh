#!/bin/bash
# Hook script for UserPromptSubmit experiment
# Outputs JSON with systemMessage and hookSpecificOutput only for /dump-args command

set -uo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
if [[ "$EVENT" == "UserPromptSubmit" ]]; then
  # Read the hook input from stdin and extract prompt with jq
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
  SKILL=$(echo "$PROMPT" | sed -n 's|^\(/[^[:space:]]*\) .*|\1|p')
else
  SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
  ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
  PROMPT="/$SKILL $ARGS"
fi

# Only output context for /dump-args command
if [[ "$PROMPT" == /dump-args* ]]; then
  echo "$INPUT" > .claude/experiments/hook-dump-$EVENT-input.json
  cat << EOF
{
  "systemMessage": "This is a system message for Event: '$EVENT'; Skill: '$SKILL'",
  "hookSpecificOutput": {
    "hookEventName": "$EVENT",
    "additionalContext": "My additional \nmulti-lined\ncontext\nhere, 'LOL'"
  }
}
EOF
fi

exit 0
