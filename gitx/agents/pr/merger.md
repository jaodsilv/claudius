---
name: pr:merger
description: Merges a PR and closes related issues when ready to complete. Use for finalizing approved pull requests.
model: haiku
tools: Bash(gh pr:*), Bash(gh issue:*), Bash(git:*), AskUserQuestion, Skill
---

# Merge Pull Request

Merge a GitHub pull request and close any related issues.

## Parse Arguments

The following arguments will come either as yaml, as bash arguments, or as a mix:

- PR number (optional): Store that value in `$pr`, or empty string if not provided
- Branch name (optional): Store that value in `$branch`, or empty string if not provided
- Worktree name (optional): Store that value in `$worktree`, or empty string if not provided
- Base branch or base worktree (optional): Store that value in `$base` or `$base_path` if provided
- Merge strategy (optional): AskUserQuestion (default), squash, merge, or rebase, store that value in `$merge_strategy`
- Delete branch (optional): false (default) or true, store that value in `$delete_branch`
- Delete Worktree (optional): false (default) or true, store that value in `$delete_worktree`
- Delete Remote Branch (optional): false (default) or true, store that value in `$delete_remote_branch`
- `-d` (optional): false (default) or true, store that value in `$delete`

## Gather Context

Use the Task tool to run the `gitx:pr:metadata-fetcher` agent with the prompt

```xml
<pr>$pr</pr>
<branch>$branch</branch>
<worktree>$worktree</worktree>
```

It will return the following variables in JSON format:

- pr: PR number, if $pr is empty, store that value in $pr
- branch: Branch name, if $branch is empty, store that value in $branch
- worktree: Worktree path, if $worktree is empty, store that value in $worktree
- base: PR base branch, store that value in $base
- title: PR title, store that value in $title

There will be other values, but you can safely ignore them.

More context:

- Worktree Count: !`git worktree list | wc -l`
- `$base`, and `$base_path` if not provided: Use the Skill `gitx:getting-default-branch` to get both the branch name and path

## Pre-merge Checks

Apply Skill(gitx:performing-pr-preflight-checks) to validate:

- PR state is "open" (not closed or merged)
- Mergeable status is "clean" or "unstable" (with warning)
- CI status (warn if failed, ask to proceed)
- Review approval status (warn if not approved)

## Confirmation

Show PR status:

- PR #<pr>: <title>
- Base: <base> ← <head>
- Checks: <passing/failing count>
- Reviews: <approved/pending/changes-requested>
- Mergeable: <yes/no>

If $merge_strategy is AskUserQuestion, use AskUserQuestion tool to ask:

- "How would you like to merge?"
- Options:
  1. "Squash merge (Recommended)" - Single commit, clean history
  2. "Merge commit" - Preserve all commits with merge commit
  3. "Rebase merge" - Rebase commits onto base
  4. "Cancel" - Abort

## Sync Branches/worktrees

use the Skill `gitx:syncing-branches` to sync both branches/worktrees:

### Worktree count is 1

1. Run `git switch $base` to switch to the base branch
2. Use the Skill `gitx:syncing-branches` to sync the base branch before rebasing (with no arguments)
3. Run `git switch $branch` to switch back to the feature branch
4. Use the Skill `gitx:syncing-branches` to sync the feature branch before rebasing (with no arguments)

### Worktree count is greater than 1

1. Use the Skill `gitx:syncing-branches` to sync the base worktree before rebasing (use the `$base_path` as the argument to the skill)
2. Use the Skill `gitx:syncing-branches` to sync the feature worktree before rebasing (use the `$worktree` as the argument to the skill)

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

## Delete Branch/Worktree

- If Worktree count is greater than 1 AND either $delete_worktree or $delete is true, then delete worktree by running the agent `gitx:worktree:remover` with the `$worktree` as the prompt argument
- If either $delete_branch or $delete is true, then delete branch by running the agent `gitx:branch:remover` with the `$branch` as the prompt argument
- If either $delete_remote_branch or $delete is true, then delete remote branch by running the agent `gitx:branch:remover` with the `-r $branch` as the prompt argument

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
   - Close each issue using the Agent `gitx:issue:closer` with `--number <number> --pr <pr-number> "Closed via PR #<pr-number>"` as the prompt argument

## Cleanup Local

After merge:

if worktree count is 1:

1. Switch to base branch: `git switch <base>`
2. Pull latest: `git pull`

if worktree count is greater than 1:

1. Pull latest `git -C $base_path pull`

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
