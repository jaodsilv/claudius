---
description: Runs the appropriate next command based on current PR workflow turn
argument-hint: "[<worktree>]"
user-invocable: true
allowed-tools: Skill
hooks:
  PreToolUse:
    - matchers: Skill
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/gitx-pre-tool.sh"
          timeout: 660
  PostToolUse:
    - matchers: Skill
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/gitx-post-tool.sh"
          timeout: 30
---

# Next Turn

Determines and runs the correct next command based on the current PR workflow turn.
Extract the value for `--turn` from $ARGUMENTS.

## Logic

Based on the value for `--turn` select the correct skill to run.

| Turn | Action |
|------|--------|
| `NO_METADATA` | Run `/gitx:pr $ARGUMENTS` to create PR first |
| `CI-REVIEW` | Run `/gitx:address-ci $ARGUMENTS` |
| `AUTHOR` | Run `/gitx:address-review $ARGUMENTS` |
| `REVIEW` | Run `/gitx:review $ARGUMENTS` |

Use the Skill tool to invoke the appropriate command.
