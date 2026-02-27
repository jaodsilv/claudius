---
description: Updates PR title and description when changes have evolved. Use for refreshing outdated PR content.
argument-hint: "[--worktree <worktree>]"
allowed-tools: Task
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Task tool to run the `gitx:pr:updater` agent with the prompt:

```
<worktree>$worktree</worktree>
$ARGUMENTS
```
