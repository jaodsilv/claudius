---
name: gitx:syncing-worktrees
description: >-
  Synchronizes git worktrees with remote before operations. Use when creating
  worktrees, before rebases, or when needing fresh main branch state.
version: 1.0.0
---

# Syncing Worktrees

Sync local branch with remote before worktree or rebase operations.

## Quick Reference

```bash
# Full sync: fetch, stash if dirty, pull, stash pop
# Returns: STASHED=true/false indicating if stash was created
```

## Pre-flight Check

Before syncing, verify not in detached HEAD:

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "Error: Cannot sync from detached HEAD state."
  echo "Please checkout a branch first: git checkout <branch-name>"
  exit 1
fi
```

## Sync Workflow

Execute in order:

### 1. Fetch Latest

```bash
git fetch origin
```

### 2. Stash If Dirty

```bash
STASHED=false
if [ -n "$(git status --porcelain)" ]; then
  git stash --include-untracked
  STASHED=true
fi
```

### 3. Pull with Rebase

```bash
PULL_OUTPUT=$(git pull --rebase origin "$CURRENT_BRANCH" 2>&1)
PULL_EXIT_CODE=$?
if [ $PULL_EXIT_CODE -ne 0 ]; then
  # Diagnose failure
  if echo "$PULL_OUTPUT" | grep -q "Could not resolve host"; then
    echo "Error: Network issue. Check internet connection."
  elif git status | grep -q "rebase in progress"; then
    echo "Error: Merge conflicts. Run: git rebase --continue or git rebase --abort"
  else
    echo "Error: Pull failed. Details: $PULL_OUTPUT"
  fi
  if [ "$STASHED" = true ]; then
    echo "Note: Changes in stash. Run 'git stash pop' after resolving."
  fi
  exit 1
fi
```

### 4. Pop Stash

```bash
if [ "$STASHED" = true ]; then
  if ! git stash pop; then
    echo "Warning: Stash pop had conflicts. Changes still in stash."
    echo "Run 'git stash pop' manually after worktree creation."
  fi
fi
```

## Main Worktree Sync

For syncing the main worktree before rebase/merge:

```bash
# Navigate to main worktree
cd ../main/

# Check status and stash if dirty
MAIN_STASHED=false
if [ -n "$(git status --porcelain)" ]; then
  git stash push -m "gitx: auto-stash $(date +%Y%m%d-%H%M%S)"
  MAIN_STASHED=true
fi

# Pull latest (fast-forward only for main)
if ! git pull --ff-only origin main; then
  echo "Warning: Main cannot fast-forward. Offer user options:"
  echo "  1. Reset to origin/main: git reset --hard origin/main"
  echo "  2. Skip sync and continue"
  echo "  3. Cancel operation"
fi

# Return to original directory
cd "$ORIGINAL_DIR"
```

## Cleanup After Operation

After successful operation, restore any stashed changes:

```bash
if [ "$MAIN_STASHED" = true ]; then
  git -C ../main/ stash pop
fi
```

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Detached HEAD | Not on a branch | `git checkout <branch>` |
| Network failure | No internet | Check connection, retry |
| Rebase conflicts | Diverged history | `git rebase --continue/--abort` |
| Stash conflicts | Local changes conflict | Resolve manually |
