---
description: Responds to PR review comments when feedback needs addressing. Use for iterating on pull request feedback.
argument-hint: "[--worktree <worktree>] [--resolve-level <all|critical|important>] [-f or --force] [[--review-comment] <review-comment>]"
user-invocable: true
allowed-tools: Task
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Task tool to run the `gitx:address-review:review-responder` agent with the prompt:

```
<worktree>$worktree</worktree>
$ARGUMENTS
```
