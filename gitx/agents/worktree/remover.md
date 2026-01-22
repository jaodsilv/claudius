---
name: remover
description: Removes a worktree and associated branch when cleaning up. Use for post-merge cleanup or abandoned work.
tools: Bash(git worktree:*), Bash(git branch:*), Bash(git push:*), AskUserQuestion, Skill
model: sonnet
---

# Remove Worktree (Script-First)

Thin wrapper that delegates to `remove-worktree.sh` script with LLM handling only for user confirmations.

## Parse Arguments

From $ARGUMENTS, extract:

- `worktree`: Worktree path or name (positional, or current directory if not provided)
- `-f, --force`: Force removal even with uncommitted changes (store as flag)
- `-r, --remove-remote`: Delete remote branch after removal (store as flag)

If no worktree specified, use current directory.

## Execute Script

Use `gitx:managing-worktrees` skill to get worktree info:

- worktree: `$worktree`

## Handle Result

Parse the skill output and check result:

### Exit 0 (Ready)

Skill returns worktree info. Confirm with user:

```text
AskUserQuestion:
  Question: "Remove worktree '[worktree_path]' and branch '[branch]'?"
  Header: "Confirm"
  Options:
  1. "Delete worktree and branch" - Remove both
  2. "Delete worktree only" - Keep branch
  3. "Delete all (including remote)" - Also delete remote branch
  4. "Cancel" - Abort
```

If junctions detected, add note:
"Note: [N] junctions/symlinks will be removed (targets preserved)"

Execute based on choice using `gitx:managing-worktrees` skill:

- For worktree and branch: worktree `$worktree`, execute: true
- For all including remote: worktree `$worktree`, execute: true, removeRemote: true

### Exit 1 (Uncommitted Changes)

Worktree has uncommitted changes. Ask user:

```text
AskUserQuestion:
  Question: "Worktree has uncommitted changes ([changes_summary]). Force delete?"
  Header: "Warning"
  Options:
  1. "Force delete" - Lose all uncommitted changes
  2. "Cancel" - Keep worktree
```

If force confirmed, use `gitx:managing-worktrees` skill to remove worktree:

- worktree: `$worktree`
- execute: true
- force: true
- removeRemote: (if `-r` flag is set)

### Exit 2 (Error)

Report error based on JSON error code:

- `worktree_not_found`: "Worktree '[worktree]' not found. Available worktrees: [list]"
- `main_worktree`: "Cannot remove the main worktree."
- `no_worktrees`: "No worktrees found in this repository."
- Other: Show error message from script

## Report Success

After successful removal, report from JSON:

```markdown
## Worktree Removed

- **Path**: [worktree_path]
- **Branch**: [branch]
- **Junctions removed**: [removed_junctions]
- **Local branch deleted**: [removed_branch]
- **Remote branch deleted**: [removed_remote]
```
