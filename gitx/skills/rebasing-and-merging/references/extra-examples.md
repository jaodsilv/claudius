# Extra Examples

Additional usage examples for rebase-merge-common.sh.

## Dirty worktree (auto-stash)

```bash
# With uncommitted changes - auto-stashes
scripts/rebase-merge-common.sh rebase --base main
# Exit 0: {"success": true, ..., "stashed": true}
```

## No auto-stash (strict mode)

```bash
# Fails if dirty
scripts/rebase-merge-common.sh rebase --base main --no-stash
# Exit 2: {"success": false, "error": "dirty_worktree", ...}
```

## Conflicts detected

```bash
scripts/rebase-merge-common.sh rebase --base main
# Exit 1: {"success": false, "conflicts": true, "conflict_files": [...]}
# Caller should use gitx:orchestrating-conflict-resolution skill
```
