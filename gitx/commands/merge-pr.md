---
description: Merges a PR and closes related issues when ready to complete. Use for finalizing approved pull requests.
argument-hint: "[PR]"
allowed-tools: Bash(gh pr:*), Bash(gh issue:*), Bash(git:*), AskUserQuestion, Skill(gitx:performing-pr-preflight-checks)
model: sonnet
---

# Merge Pull Request

Merge a GitHub pull request and close any related issues.

## Parse Arguments

From $ARGUMENTS, extract:
- PR number (optional): If not provided, use PR for current branch

## Gather Context

Get PR information:
- Current branch: !`git branch --show-current`

If PR number provided:
- `gh pr view <number> --json number,title,state,mergeable,mergeStateStatus,headRefName,baseRefName,body,reviews`

If no PR number:
- `gh pr view --json number,title,state,mergeable,mergeStateStatus,headRefName,baseRefName,body,reviews 2>/dev/null`

If no PR found:
- Report: "No PR found"
- List open PRs: `gh pr list --state open --limit 5`
- Use AskUserQuestion to select

## Pre-merge Checks

Apply Skill(gitx:performing-pr-preflight-checks) to validate:

- PR state is "open" (not closed or merged)
- Mergeable status is "clean" or "unstable" (with warning)
- CI status (warn if failed, ask to proceed)
- Review approval status (warn if not approved)

## Confirmation

Use AskUserQuestion:

Show PR status:
- PR #<number>: <title>
- Base: <base> ← <head>
- Checks: <passing/failing count>
- Reviews: <approved/pending/changes-requested>
- Mergeable: <yes/no>

Ask merge strategy:
- "How would you like to merge?"
- Options:
  1. "Squash merge (Recommended)" - Single commit, clean history
  2. "Merge commit" - Preserve all commits with merge commit
  3. "Rebase merge" - Rebase commits onto base
  4. "Cancel" - Abort

## Execute Merge

Based on selected strategy:

```bash
# Squash merge
gh pr merge <number> --squash

# Merge commit
gh pr merge <number> --merge

# Rebase
gh pr merge <number> --rebase
```

Add delete branch flag if appropriate:
- `--delete-branch` to clean up after merge

## Close Related Issues

After successful merge:

1. Parse PR body for issue references:
   - "Closes #123"
   - "Fixes #456"
   - "Resolves #789"

2. For each referenced issue:
   - Check if already closed: `gh issue view <number> --json state`
   - If still open and using "Closes/Fixes/Resolves": It should auto-close
   - Verify closure

3. If issues didn't auto-close:
   - `gh issue close <number>` for each
   - Add comment: "Closed via PR #<pr-number>"

## Cleanup Local

After merge:

1. Switch to base branch: `git switch <base>`
2. Pull latest: `git pull`
3. Delete local branch: `git branch -d <merged-branch>`
4. Remove worktree if exists: Check `git worktree list`

## Report Results

Show merge outcome:
- PR merged successfully
- Merge commit SHA (if applicable)
- Issues closed: list
- Branch cleanup: done/pending
- Link to merged PR

```text
PR #123 merged successfully!

Merge commit: abc1234
Issues closed: #45, #67
Branch 'feature/my-feature' deleted locally

View: https://github.com/owner/repo/pull/123
```

## Error Handling

1. PR not found: Show list of open PRs.
2. Not mergeable: Explain why and suggest fix.
3. Merge conflicts: Suggest resolving first.
4. Failed checks: Warn but allow override with confirmation.
5. Permission denied: Check write access.
6. Issues not found: Note but continue with merge.
