---
description: Merges a PR and closes related issues when ready to complete. Use for finalizing approved pull requests.
argument-hint: "[pr_number] [--worktree <path>] [--squash|--merge|--rebase] [-d | [--delete-branch] [--delete-worktree] [--delete-remote]]
allowed-tools: Task
model: sonnet
---

Using the Task tool, run the `gitx:pr:merger` skill with the following arguments:

```bash
Task(gitx:pr:merger):
  $ARGUMENTS
```
