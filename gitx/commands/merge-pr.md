---
description: Merges a PR and closes related issues when ready to complete. Use for finalizing approved pull requests.
argument-hint: "[PR] [branch] [worktree]"
allowed-tools: Task
model: sonnet
---

Use Task tool to run the agent `gitx:pr:merger` with the arguments from $ARGUMENTS to merge a PR and close any related issues.
