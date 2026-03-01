# Extra Examples

Additional usage examples for merge-pr.sh.

## Full cleanup including worktree

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/prs/merge-pr.sh 123 --squash --delete-branch --delete-worktree --delete-remote
# Merges, removes worktree, deletes branches
```

## Explicit merge commit

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/prs/merge-pr.sh 123 --merge
# Uses merge commit instead of squash
```
