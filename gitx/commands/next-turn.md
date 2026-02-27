---
description: Runs the appropriate next command based on current PR workflow turn
argument-hint: "[[--worktree] <worktree>]"
allowed-tools: Skill
hooks:
  PreToolUse:
    - matchers: Skill
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/gitx-pre-skill.sh"
          timeout: 660
  PostToolUse:
    - matchers: Skill
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/gitx-post-skill.sh"
          timeout: 30
---

# Next Turn

Determines and runs the correct next command based on the current PR workflow turn.

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Extract the value for `--turn` from $ARGUMENTS (passed by the hook).

## Logic

Based on the value for `--turn` select the correct skill to run.

| Turn | Action |
|------|--------|
| `NO_METADATA` | Run `/gitx:pr --worktree $worktree` to create PR first |
| `CI-REVIEW` | Run `/gitx:address-ci --worktree $worktree` |
| `AUTHOR` | Run `/gitx:address-review --worktree $worktree` |
| `REVIEW` | Run `/gitx:review --worktree $worktree` |

Use the Skill tool to invoke the appropriate command.
