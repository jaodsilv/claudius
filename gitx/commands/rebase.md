---
description: Rebase current branch onto base branch (default: main)
argument-hint: "[--base branch]"
allowed-tools: Bash(git rebase:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), AskUserQuestion
---

# Rebase Branch

Rebase the current branch onto a base branch to incorporate upstream changes and maintain a linear history.

## Parse Arguments

From $ARGUMENTS, extract:
- `--base <branch>`: Base branch to rebase onto (default: main)

## Gather Context

Get repository state:
- Current branch: !`git branch --show-current`
- Main branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`
- Working tree status: !`git status --porcelain`
- Commits to rebase: !`git log --oneline <base>..HEAD 2>/dev/null | head -20`

Determine base branch:
- If --base provided: Use that branch
- Otherwise: Use main branch (detected above)

## Pre-flight Checks

### Check for clean working tree
If there are uncommitted changes:
- Use AskUserQuestion: "You have uncommitted changes. Stash them before rebasing?"
- Options: "Stash and continue", "Cancel"
- If stash: `git stash push -m "gitx: pre-rebase stash"`

### Check commits to rebase
Show commits that will be rebased:
- Count: number of commits
- List: abbreviated commit messages

## Fetch Latest

Update remote tracking:
- `git fetch origin <base-branch>`

Show what's new on base:
- `git log --oneline HEAD..origin/<base-branch> | head -10`

## Confirmation

Use AskUserQuestion to confirm rebase:

Show:
- Current branch: <name>
- Base branch: origin/<base>
- Commits to rebase: <count>
- New commits from base: <count>

Options:
1. "Proceed with rebase" - continue
2. "View commits in detail" - show more info
3. "Cancel" - abort

## Execute Rebase

Run the rebase:
- `git rebase origin/<base-branch>`

## Handle Conflicts

If conflicts occur:

1. Report conflict status: `git status`
2. Show conflicting files
3. Use AskUserQuestion:
   - "Conflicts detected. How would you like to proceed?"
   - Options:
     - "Help me resolve conflicts" - provide guidance on each file
     - "Abort rebase" - `git rebase --abort`
     - "I'll resolve manually" - provide instructions

If helping with conflicts:
- For each conflicting file, show the conflict markers
- Suggest resolution based on context
- After resolution: `git add <file>` then `git rebase --continue`

## Pop Stash

If changes were stashed:
- `git stash pop`
- Report if conflicts with stash

## Report Results

Show rebase outcome:
- Success: "Rebased <count> commits onto <base>"
- New HEAD commit
- Suggest: "Run `git push --force-with-lease` to update remote (if previously pushed)"

## Error Handling

- Already up to date: Report "Already up to date with <base>"
- Unrelated histories: Suggest `--allow-unrelated-histories` only with explicit confirmation
- Merge conflicts: Guide through resolution (see above)
- Rebase in progress: Offer to continue, skip, or abort
