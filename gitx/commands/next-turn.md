---
description: Runs the appropriate next command based on current PR workflow turn
argument-hint: "[[--worktree] <worktree>] [--no-metadata-sync]"
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

## Modes

Extract from $ARGUMENTS:

- **No metadata sync (--no-metadata-sync)**: If `--no-metadata-sync` is present,
  set `$NO_METADATA_SYNC="true"`, otherwise `"false"`. When `"true"`, the
  downstream skill invocation MUST also include `--no-metadata-sync` so the flag
  flows down naturally.

## Logic

Based on the value for `--turn` select the correct skill to run. When
`$NO_METADATA_SYNC` is `"true"`, append ` --no-metadata-sync` to the args of
the chosen downstream skill (the table below shows the base form; for example,
when `$NO_METADATA_SYNC="true"` and turn is `REVIEW`, run
`/gitx:review --worktree $worktree --no-metadata-sync`).

| Turn | Action |
| :--- | :----- |
| `NO_METADATA` | Run `/gitx:pr --worktree $worktree` to create PR first |
| `CI-REVIEW` | Run `/gitx:address-ci --worktree $worktree` |
| `AUTHOR` | Run `/gitx:address-review --worktree $worktree` |
| `REVIEW` | Run `/gitx:review --worktree $worktree` |

Use the Skill tool to execute the appropriate command based on the turn value.
