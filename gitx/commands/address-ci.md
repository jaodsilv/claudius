---
description: Responds to CI failures when feedback needs addressing. Use for iterating on pull request feedback.
argument-hint: "[--pr <pr>] [--worktree <worktree>] [--branch <branch>]"
allowed-tools: Task
model: haiku
---

# Verify and Address CI Feedback

Use the Task tool to run the `gitx:address-review:ci-status-worker` agent using $ARGUMENTS as prompt

## Important Guidelines

1. **Agent execution**: Execute agent using the Task tool. Do not simulate or skip actual agent execution.
