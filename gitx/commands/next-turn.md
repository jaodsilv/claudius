---
description: Runs the appropriate next command based on current PR workflow turn
allowed-tools: Bash, Skill, Read
argument-hint: [worktree]
---

# Next Turn

Determines and runs the correct next command based on the current PR workflow turn.

## Context

- Current turn: !`yq -r '.turn // "unknown"' $1.thoughts/pr/metadata.yaml 2>/dev/null || echo "NO_METADATA"`

## Logic

Based on the turn value:

| Turn | Action |
|------|--------|
| `NO_METADATA` | Run `/gitx:pr` to create PR first |
| `CI-REVIEW` | Run `/gitx:address-ci` |
| `AUTHOR` | Run `/gitx:address-review` |
| `REVIEW` | Run `/gitx:review` |

Use the Skill tool to invoke the appropriate command.
