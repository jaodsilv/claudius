---
description: Updates PR title and description when changes have evolved. Use for refreshing outdated PR content.
argument-hint: "[--worktree <worktree>]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Agent tool to run the `gitx:pr:updater` agent with the prompt:

```markdown
<worktree>$worktree</worktree>
$ARGUMENTS
```
