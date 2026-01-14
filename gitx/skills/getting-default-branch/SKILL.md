---
name: gitx:getting-default-branch
description: >-
  Gets the default branch name and path from the git worktree list.
version: 1.0.0
allowed-tools: Bash(git:*)
model: haiku
---

# Getting Default Branch

Gets the default branch name and path from the git worktree list.

Set `$name` to the default branch name: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`

Set `$path` to the default branch worktree path: !`git worktree list | rg "\[$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')$\]" | awk -F' ' '{print $1}'`

The final result is

```yaml
defaultBranch: $name
defaultBranchPath: $path
```
