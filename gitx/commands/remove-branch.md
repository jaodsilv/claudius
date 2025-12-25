---
description: Remove branch (local and/or remote)
argument-hint: "[branch-name] [-f force] [-r remove-remote] [-ro remote-only]"
allowed-tools: Bash(git branch:*), Bash(git push:*), Bash(git switch:*), Bash(git checkout:*), AskUserQuestion
---

# Remove Branch

Remove a git branch locally and/or from the remote repository.

## Parse Arguments

From $ARGUMENTS, extract:
- Branch name (positional, or current branch if not provided)
- `-f` or `--force`: Force delete even if not fully merged
- `-r` or `--remove-remote`: Also delete remote branch
- `-ro` or `--remote-only`: Only delete remote branch, keep local

## Gather Context

Get branch information:
- Current branch: !`git branch --show-current`
- Main branch: !`ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && echo "${ref#refs/remotes/origin/}" || echo "main"`
- All local branches: !`git branch --list`
- Remote tracking status: !`git branch -vv`

Identify target branch:
- If name provided: Use that branch
- If no name: Use current branch (with extra confirmation)

## Validation

Check if operation is safe:
1. Cannot delete main/master branch without explicit confirmation
2. If deleting current branch, must switch first
3. Check if branch has unmerged commits

Get merge status:
- `git branch --merged <main-branch>` to check if target is merged
- If not merged and not forcing: Warn user

## Confirmation

Use AskUserQuestion to confirm:

Show what will be deleted:
- Local branch: <name> (if not -ro)
- Remote branch: origin/<name> (if -r or -ro)
- Merge status: "merged into main" or "NOT MERGED - has X commits ahead"

If deleting current branch:
- "You are currently on this branch. You will be switched to <main> first."

Options:
1. "Delete branch" - proceed
2. "Delete local only" - skip remote even if -r was specified
3. "Cancel" - abort

If targeting main/master:
- Add explicit warning: "This is a protected branch. Are you SURE?"
- Require typing confirmation

## Execution

### Step 1: Switch if on target branch

If current branch is target and not -ro:
- `git switch <main-branch>`

### Step 2: Delete local branch (unless -ro)

- Standard: `git branch -d <branch-name>`
- Force: `git branch -D <branch-name>`

### Step 3: Delete remote branch (if -r or -ro)

- Check if remote exists: `git ls-remote --heads origin <branch-name>`
- If exists: `git push origin --delete <branch-name>`
- If not exists: Note "Remote branch does not exist"

## Report Results

Summarize actions:
- Local branch: deleted / skipped / not deleted (error)
- Remote branch: deleted / skipped / did not exist

Provide cleanup suggestion:
- "Run `git fetch --prune` to clean up stale remote references"

## Error Handling

1. Branch not found: List available branches.
2. Permission denied on remote: Check authentication.
3. Branch not fully merged: Explain and suggest -f flag.
4. Cannot delete current branch: Auto-switch first.
