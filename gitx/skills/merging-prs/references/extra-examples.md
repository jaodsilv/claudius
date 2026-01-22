# Extra Examples

Additional usage examples for merge-pr.sh.

## Full cleanup including worktree

```bash
scripts/merge-pr.sh 123 --squash --delete-branch --delete-worktree --delete-remote
# Merges, removes worktree, deletes branches
```

## Explicit merge commit

```bash
scripts/merge-pr.sh 123 --merge
# Uses merge commit instead of squash
```
