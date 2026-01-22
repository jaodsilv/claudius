---
name: remover
description: Removes a branch when cleaning up. Use for post-merge cleanup or abandoned work.
tools: Bash(git branch:*), Bash(git push:*), Bash(git switch:*), AskUserQuestion, Skill
model: sonnet
---

# Remove Branch (Script-First)

Thin wrapper that delegates to `remove-branch.sh` script with LLM handling only for user confirmations.

## Parse Arguments

From $ARGUMENTS, extract:

- `branch`: Branch name (positional, or current branch if not provided)
- `-f, --force`: Force delete even if unmerged (store as flag)
- `-r, --remove-remote`: Also delete remote branch (store as flag)
- `--remote-only`: Only delete remote branch, keep local (store as flag)

If no branch specified, use current branch (with extra confirmation).

## Execute Script

Use `gitx:managing-branches` skill to get branch info:

- branch: `$branch`
- remoteOnly: (if `--remote-only` flag is set)

## Handle Result

Parse the skill output and check result:

### Exit 0 (Ready - Merged)

Branch is merged. Confirm with user:

```text
AskUserQuestion:
  Question: "Delete branch '[branch]'? (merged into [default_branch])"
  Header: "Confirm"
  Options:
  1. "Delete local only"
  2. "Delete local and remote"
  3. "Cancel"
```

Execute based on choice using `gitx:managing-branches` skill:

- For local only: branch `$branch`, execute: true
- For local and remote: branch `$branch`, execute: true, removeRemote: true

### Exit 1 (Unmerged)

Branch has unmerged commits. Warn user:

```text
AskUserQuestion:
  Question: "Branch '[branch]' is NOT merged into [default_branch]. This may lose work.\n\nLast commit: [last_commit]"
  Header: "Warning"
  Options:
  1. "Force delete anyway" - Delete unmerged branch
  2. "Cancel" - Keep branch
```

If force confirmed, use `gitx:managing-branches` skill to remove branch:

- branch: `$branch`
- execute: true
- force: true
- removeRemote: (if `-r` flag is set)

### Exit 2 (Error)

Report error based on JSON error code:

- `branch_not_found`: "Branch '[branch]' not found locally or on remote."
- `remote_not_found`: "Remote branch 'origin/[branch]' not found."
- `in_worktree`: "Branch '[branch]' is checked out in worktree '[path]'. Remove the worktree first."
- Other: Show error message from script

## Report Success

After successful removal, report from JSON:

```markdown
## Branch Removed

- **Branch**: [branch]
- **Switched from**: [switched_from] (if was current)
- **Local deleted**: [removed_local]
- **Remote deleted**: [removed_remote]

To clean up stale remote references:
```bash
git fetch --prune
```
```

## Remote-Only Mode

If `--remote-only` specified:

1. Skip local branch operations
2. Use `gitx:managing-branches` skill to delete remote only:
   - branch: `$branch`
   - remoteOnly: true
   - execute: true
3. Report only remote deletion status
