---
description: Merge base branch into current branch (default: main)
argument-hint: "[--base branch]"
allowed-tools: Bash(git merge:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), AskUserQuestion
---

# Merge Branch

Merge a base branch into the current branch to incorporate upstream changes.

## Parse Arguments

From $ARGUMENTS, extract:
- `--base <branch>`: Branch to merge from (default: main)

## Gather Context

Get repository state:
- Current branch: !`git branch --show-current`
- Main branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`
- Working tree status: !`git status --porcelain`

Determine base branch:
- If --base provided: Use that branch
- Otherwise: Use main branch

## Pre-flight Checks

### Check for clean working tree
If uncommitted changes exist:
- Use AskUserQuestion: "You have uncommitted changes. Stash them before merging?"
- Options: "Stash and continue", "Cancel"
- If stash: `git stash push -m "gitx: pre-merge stash"`

## Fetch Latest

Update remote tracking:
- `git fetch origin <base-branch>`

Show incoming changes:
- `git log --oneline HEAD..origin/<base-branch> | head -10`

## Confirmation

Use AskUserQuestion:

Show:
- Current branch: <name>
- Merging from: origin/<base>
- Incoming commits: <count>

Options:
1. "Proceed with merge" - continue
2. "View changes in detail" - show diff summary
3. "Cancel" - abort

## Execute Merge

Run the merge:
- `git merge origin/<base-branch>`

## Handle Conflicts

If conflicts occur:

1. Report conflict status: `git status`
2. Show conflicting files
3. Use AskUserQuestion:
   - "Merge conflicts detected. How would you like to proceed?"
   - Options:
     - "Help me resolve conflicts" - provide guidance
     - "Abort merge" - `git merge --abort`
     - "I'll resolve manually" - provide instructions

If helping with conflicts:
- For each conflicting file, analyze the conflict
- Show both versions with context
- Suggest resolution
- After resolution: `git add <file>`
- When all resolved: Commit the merge

## Pop Stash

If changes were stashed:
- `git stash pop`
- Report any conflicts with stash

## Report Results

Show merge outcome:
- Success: "Merged <base> into <current>: <count> commits incorporated"
- Merge commit hash (if not fast-forward)
- Summary of changes

## Error Handling

- Already up to date: Report "Already up to date with <base>"
- Merge conflicts: Guide through resolution (see above)
- Merge in progress: Offer to continue or abort
