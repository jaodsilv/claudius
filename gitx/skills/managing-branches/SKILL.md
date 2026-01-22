---
name: gitx:managing-branches
description: >-
  Scripts for removing git branches with safety checks.
  Invoked when deleting branches after merge or cleanup.
allowed-tools: Bash(scripts/remove-branch.sh:*)
model: sonnet
---

# Managing Branches

Remove git branches with merge status validation and safety checks.

## Scripts

### remove-branch.sh

Removes a branch with safety checks for worktrees and unmerged commits.

```bash
scripts/remove-branch.sh <branch> [options]
```

**Options**: `-f` force, `-r` remove remote, `--remote-only`, `--execute`

**Exit codes**: 0 ready/merged, 1 unmerged (needs confirmation), 2 error

## Safety Features

- Cannot delete branch checked out in worktree
- Auto-switches if deleting current branch
- Warns if branch has unmerged commits
