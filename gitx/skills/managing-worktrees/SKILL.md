---
name: gitx:managing-worktrees
description: >-
  Scripts for creating and removing git worktrees with smart naming, junction handling, and cleanup.
  Invoked when managing worktrees for isolated development environments.
allowed-tools: Bash(scripts/remove-worktree.sh:*), Bash(scripts/worktree-create.sh:*)
model: sonnet
---

# Managing Worktrees

Create and remove git worktrees with smart branch/directory naming and Windows junction handling.

## Scripts

### remove-worktree.sh

Removes a worktree with optional branch cleanup.

```bash
scripts/remove-worktree.sh <worktree> [options]
```

**Options**: `-f` force, `-r` remove remote, `--execute` perform removal

**Exit codes**: 0 ready, 1 uncommitted changes, 2 error

### worktree-create.sh

Creates a worktree with the specified branch and directory.

```bash
scripts/worktree-create.sh --branch <name> --dir <path> [--base <branch>]
```

**Options**:

- `--branch` (required) - Branch name, created if doesn't exist
- `--dir` (required) - Directory path for worktree
- `--base` - Base branch for new branches (only used if branch doesn't exist)

**Exit codes**: 0 success, 2 error

## Two-Phase Pattern

The remove-worktree.sh script uses info mode by default (outputs JSON for user confirmation), then `--execute` to perform the action.
