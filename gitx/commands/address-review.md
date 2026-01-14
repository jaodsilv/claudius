---
description: Responds to PR review comments when feedback needs addressing. Use for iterating on pull request feedback.
argument-hint: "[--pr <pr>] [--worktree <worktree>] [--branch <branch>] [--address-level <address-level>] [<review-comment>]"
allowed-tools: Task
model: haiku
---

# Verify and Address Review Feedback

Using the Task tool, delegate to the `gitx:address-review:review-responder` agent with the value of $ARGUMENTS as its prompt

## Important Guidelines

1. **Agent execution**: Execute agent using the Task tool. Do not simulate or skip actual agent execution.
