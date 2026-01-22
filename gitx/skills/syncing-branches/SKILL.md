---
name: gitx:syncing-branches
description: >-
  Synchronizes git branches with remote before operations. Use before rebasing or after a change made by a CI pipeline on a PR branch, before committing.
allowed-tools: Bash(scripts/sync-branch.sh:*)
model: sonnet
---

# Syncing Branches

Sync context branch with remote when:

- before rebasing
- after a change made by a CI pipeline on a PR branch, before writing a new commit.

## Usage

Run the sync script with optional worktree path:

```bash
scripts/sync-branch.sh [worktree_path]
```

If no path provided, uses current directory.

## Output

The script returns JSON with sync results:

```json
{
  "success": true,
  "branch": "feature/my-branch",
  "stashed": false,
  "worktree": "/d/src/project"
}
```

On error:

```json
{
  "success": false,
  "branch": "feature/my-branch",
  "stashed": true,
  "stash_conflict": true,
  "error": "Stash pop had conflicts. Resolve manually."
}
```

## Error Handling

| Error | Cause | Resolution |
| ----- | ----- | ---------- |
| Detached HEAD | Not on a branch | `git checkout <branch>` |
| Network failure | No internet | Check connection, retry |
| Rebase conflicts | Diverged history | `git rebase --continue/--abort` |
| Stash conflicts | Local changes conflict | Resolve manually |
