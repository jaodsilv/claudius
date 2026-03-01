---
description: Merges a PR and closes related issues when ready to complete. Use for finalizing approved pull requests.
argument-hint: "[[--pr] <pr_number>] [--worktree <path>] [--squash|--merge|--rebase] [-d] [--delete-branch] [--delete-worktree] [--delete-remote]"
allowed-tools: Task
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument from $ARGUMENTS if present.

## Step 1: Run Agent

Using the Agent tool, run the `gitx:pr:merger` agent with the following arguments:

```
--worktree $worktree $ARGUMENTS
```
