---
name: gitx:syncing-branches
description: >-
  Synchronizes git branches with remote before operations. Use before rebasing or after a change made by a CI pipeline on a PR branch, before committing.
version: 1.0.0
allowed-tools: Bash(git:*)
model: haiku
---

# Syncing Branches

Sync context branch with remote when:

- before rebasing
- after a change made by a CI pipeline on a PR branch, before writing a new commit.

## Quick Reference

```bash
# Full sync: fetch, stash if dirty, pull, stash pop
# Returns: STASHED=true/false indicating if stash was created
```

## Pre-flight Check

Set `$pwd` to the directory of the worktree you want to sync, or, by default, the current directory (!`pwd`)

Before syncing, verify not in detached HEAD:

Set `$branch` to the current branch name: `git -C $pwd branch --show-current`

If `$branch` is empty, let the user know they are in a detached HEAD state and exit the skill

## Sync Workflow

Execute in order:

### 1. Preparing For Syncing

- Fetch: !`git fetch origin`

### 2. Stash If Dirty

Using the Bash tool run:

```bash
git -C $pwd status --porcelain
```

and if the output is not empty, then using the Bash tool run:

```bash
git -C $pwd stash --include-untracked
```

And remember if you did stash items

### 3. Pull

Using the Bash tool:

```bash
git -C $pwd pull --rebase
```

### 4. Push

Using the Bash tool:

```bash
git -C $pwd push
```

### 5. Pop Stash

If you stashed items, run using the Bash tool:

```bash
git -C $pwd stash pop
```

If that command returned an error, let the user know stash pop had conflicts in the current path

## Error Handling

| Error | Cause | Resolution |
| ----- | ----- | ---------- |
| Detached HEAD | Not on a branch | `git checkout <branch>` |
| Network failure | No internet | Check connection, retry |
| Rebase conflicts | Diverged history | `git rebase --continue/--abort` |
| Stash conflicts | Local changes conflict | Resolve manually |
