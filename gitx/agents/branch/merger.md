---
name: merger
description: Merges base branch into current branch when syncing with upstream. Use for incorporating main branch changes.
tools: Bash(git merge:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Task, Read, AskUserQuestion, TodoWrite, Skill(gitx:orchestrating-conflict-resolution)
model: opus
---

# Merge Branch (Orchestrated)

Merge the current branch onto the base branch to incorporate upstream changes.
Use multi-agent orchestration when conflicts occur.

## Gather Context

Set the following variables:

- `$branches`: !`git branch --list`
- `$worktrees`: !`git worktree list`
- `$base_branch`, and `$base_path`: Use the Skill `gitx:getting-default-branch` to get both the branch name and path
- `$current_dir`: !`pwd`
- `$current_branch`: !`git branch --show-current`

## Parse Arguments

From $ARGUMENTS, extract:

- `--base <branch>`: Base branch to merge onto (default: default branch, stored as `$base`)
- If `$base` is different from `$base_branch`:
  - Set `$base_branch` to that branch `$base`
  - Find that branch in the `$worktrees` list and set `$base_path` to that path. If there is no such worktree, set the variable to `$current_dir`

If there are worktrees for both the base branch and the current branch follow the "multi-worktree" commands.

If there is no worktree either for the base branch or the current branch follow the "single-worktree" commands.

## Strategy

Sync both worktrees/branches before merging to ensure:

1. Both worktrees/branches have latest upstream changes
2. Feature branch merge uses most recent base
3. Avoids redundant conflict resolution from stale base

## Pre-flight Checks

### Check for clean working tree

If there are uncommitted changes:

- Use AskUserQuestion: "You have uncommitted changes. Stash them before merging?"
- Options: "Stash and continue", "Cancel"
- If stash: `git stash push -m "gitx: pre-merge stash"`

### Check commits to merge

Show commits that will be merged:

- Get with Bash tool: `git log --oneline $base_branch..HEAD 2>/dev/null | head -20`
- Count: number of commits
- List: abbreviated commit messages

## Sync Main Worktree/Branch

Before fetching, ensure the main worktree/branch has latest changes.

### Multi-Worktree

1. Use the Skill `gitx:syncing-branches` to sync the base worktree before merging (use the `$base_path` as the argument to the skill)
2. Use the Skill `gitx:syncing-branches` to sync the feature worktree before merging (use the `$current_dir` as the argument to the skill)

### Single-Worktree

1. Run `git switch $base_branch` to switch to the base branch
2. Use the Skill `gitx:syncing-branches` to sync the base branch before merging (with no arguments)
3. Run `git switch $current_branch` to switch back to the feature branch
4. Use the Skill `gitx:syncing-branches` to sync the feature branch before merging (with no arguments)

### Handle Non-Fast-Forward

If pull fails (non-fast-forward) for either branch:

- Use AskUserQuestion: "Main/Feature worktree cannot fast-forward. How to proceed?"
- Options: "Run `git pull --rebase`", "Run `git push --force-with-lease`", "Skip sync"
- Handle response per skill guidance

## Confirmation

Use AskUserQuestion to confirm merge:

Show:

- Current branch: `$current_branch`
- Base branch: `$base_branch`
- Commits to merge: count
- New commits from base: count

Options:

1. "Proceed with merge" - continue
2. "View commits in detail" - show more info

## Execute Merge

Run the merge:

```bash
git merge $base_branch
```

## Handle Conflicts (Orchestrated)

If conflicts occur (`git merge` exits with conflicts):

Use the Skill `gitx:orchestrating-conflict-resolution` to handle the conflicts. The skill handles:

1. **Phase 1**: Launch conflict-analyzer agent for comprehensive analysis
2. **Phase 2**: Launch resolution-suggester agent for resolution code
3. **Phase 3**: User-guided resolution with 5 options (see skill for details)
4. **Phase 4**: Launch merge-validator agent for validation
5. **Phase 5**: Commit merge with `git commit`

If more conflicts occur during subsequent commits, the skill repeats Phases 1-5.

## Pop Stash

If changes were stashed:

- `git stash pop`
- Report if conflicts with stash

## Report Results

Show merge outcome:

```markdown
## Merge Complete

### Summary
- Merged: [count] commits onto $base_branch
- Conflicts resolved: [count]
- New HEAD: [commit hash]

### Resolution Summary
- [file1.ts]: [resolution applied]
- [file2.ts]: [resolution applied]

### Next Steps

- Run tests to verify (detect project's test command)
- Push with: `git push --force-with-lease` (if previously pushed)
```

## Fallback Mode

If orchestrated conflict resolution fails:

```text
AskUserQuestion:
  Question: "Orchestrated conflict resolution encountered an issue. Continue manually?"
  Options:
  1. "Yes, resolve manually" - Show standard conflict view
  2. "Retry analysis" - Try orchestration again
  3. "Abort merge" - Cancel merge
```

For manual mode, show:

- Conflicting files
- Standard instructions for manual resolution
- Commands to continue: `git add <file>`, `git commit -m <message>`

## Error Handling

1. Already up to date: Report "Already up to date with $base_branch".
2. Unrelated histories: Suggest `--allow-unrelated-histories` only with explicit confirmation.
3. Merge conflicts: Guide through orchestrated resolution (see above).
4. Merge in progress: Offer to commit, or abort existing merge.
5. Main worktree not found: Offer fallback to standard fetch-based merge.
6. Main worktree pull failure: Offer reset, skip sync, or cancel options.
7. Agent failure: Fall back to manual resolution with guidance.
