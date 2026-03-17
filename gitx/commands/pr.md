---
description: Creates a pull request when ready to merge changes. Use for feature completion, bug fixes, or any branch ready for review.
argument-hint: "[[--worktree] <worktree>]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Agent tool to run the `gitx:pr:creator` agent with the following prompt exactly as-is:

```markdown
--worktree $worktree $ARGUMENTS
```
