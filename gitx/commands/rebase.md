---

description: Rebases current branch onto base branch when syncing with upstream. Use for maintaining linear history on feature branches.
argument-hint: "[--base branch]"
allowed-tools: Bash(git rebase:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git add:*), Bash(git stash:*), Bash(git pull:*), Bash(pwd:*), Bash(cd:*), Bash(test:*), Task, Read, AskUserQuestion, TodoWrite, Skill(gitx:syncing-worktrees), Skill(gitx:orchestrating-conflict-resolution)
model: opus
---

# Rebase Branch (Orchestrated)

Rebase the current branch onto the base branch to incorporate upstream changes.
Use multi-agent orchestration when conflicts occur.

## Worktree Strategy

This command syncs the main branch worktree before rebasing to ensure:

1. Main worktree has latest upstream changes
2. Feature branch rebase uses most recent base
3. Avoids redundant conflict resolution from stale main

Navigate to main worktree (`../main/`), pull latest, then rebase feature branch.

## Parse Arguments

From $ARGUMENTS, extract:

- `--base <branch>`: Base branch to rebase onto (default: main, stored as `$base_branch`)

## Gather Context

Get repository state:

- Current branch: !`git branch --show-current` → Store as `$current_branch`
- Default base: !`ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && echo "${ref#refs/remotes/origin/}" || echo "main"`
- Working tree status: !`git status --porcelain`
- Current directory: !`pwd` → Store as `$original_dir`

Determine base branch:

- If --base provided: Use that branch as `$base_branch`
- Otherwise: Use detected default as `$base_branch`

Show commits to rebase:

```bash
git log --oneline $base_branch..HEAD | head -20
```

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

## Sync Main Worktree

Before fetching, ensure the main worktree has latest changes.

### Validate Worktree Exists

Check if main worktree exists:

```bash
test -d ../main && echo "exists" || echo "missing"
```

If missing:

- Use AskUserQuestion: "Main worktree not found at ../main/.
  Proceed with standard rebase?"
- Options: "Yes (skip worktree sync)", "No (cancel)"
- If No: Exit with message "Set up main worktree: `git worktree add ../main $base_branch`"
- If Yes: Skip to "Fetch Latest" section

### Sync Using Skill

If main worktree exists, use Skill tool with gitx:syncing-worktrees following
the "Main Worktree Sync" pattern. The skill handles:

1. Navigate to main worktree (`../main/`)
2. Stash uncommitted changes if dirty (sets `$main_stash_created` flag)
3. Pull latest with fast-forward only
4. Return to original directory

If pull fails (non-fast-forward):

- Use AskUserQuestion: "Main worktree cannot fast-forward. How to proceed?"
- Options: "Reset to origin/$base_branch", "Skip sync", "Cancel rebase"
- Handle response per skill guidance

### Verify Sync

```bash
MAIN_HEAD=$(git -C ../main/ rev-parse HEAD)
ORIGIN_HEAD=$(git rev-parse origin/$base_branch)
if [ "$MAIN_HEAD" = "$ORIGIN_HEAD" ]; then
  echo "✓ Main worktree synchronized with origin/$base_branch"
else
  echo "⚠️  Warning: Main worktree HEAD differs from origin/$base_branch"
fi
```

## Fetch Latest

Update remote tracking:

```bash
git fetch origin $base_branch
```

Show what's new on base:

```bash
git log --oneline HEAD..origin/$base_branch | head -10
```

## Confirmation

Use AskUserQuestion to confirm rebase:

Show:

- Current branch: `$current_branch`
- Base branch: `origin/$base_branch`
- Commits to rebase: count
- New commits from base: count

Options:

1. "Proceed with rebase" - continue
2. "View commits in detail" - show more info
3. "Cancel" - abort

## Execute Rebase

Run the rebase:

```bash
git rebase origin/$base_branch
```

## Handle Conflicts (Orchestrated)

If conflicts occur (`git rebase` exits with conflicts):

Use Skill tool with gitx:orchestrating-conflict-resolution. The skill handles:

1. **Phase 1**: Launch conflict-analyzer agent for comprehensive analysis
2. **Phase 2**: Launch resolution-suggester agent for resolution code
3. **Phase 3**: User-guided resolution with 5 options (see skill for details)
4. **Phase 4**: Launch merge-validator agent for validation
5. **Phase 5**: Continue rebase with `git rebase --continue`

If more conflicts occur during subsequent commits, the skill repeats Phases 1-5.

## Pop Stash

If changes were stashed:

- `git stash pop`
- Report if conflicts with stash

## Report Results

Show rebase outcome:

```markdown
## Rebase Complete

### Summary
- Rebased: [count] commits onto $base_branch
- Conflicts resolved: [count]
- New HEAD: [commit hash]

### Resolution Summary
- [file1.ts]: [resolution applied]
- [file2.ts]: [resolution applied]

### Next Steps

- Run tests to verify (detect project's test command)
- Push with: `git push --force-with-lease` (if previously pushed)
```

## Cleanup Main Worktree

After successful rebase, restore any stashed changes in the main worktree
using the "Cleanup After Operation" pattern from gitx:syncing-worktrees skill.

If `$main_stash_created` is true, pop the stash in `../main/`.

**Note**: This cleanup only runs after a successful rebase. If the rebase fails
or is aborted, manually check `../main/` for stashed changes.

## Fallback Mode

If orchestrated conflict resolution fails:

```text
AskUserQuestion:
  Question: "Orchestrated conflict resolution encountered an issue. Continue manually?"
  Options:
  1. "Yes, resolve manually" - Show standard conflict view
  2. "Retry analysis" - Try orchestration again
  3. "Abort rebase" - Cancel rebase
```

For manual mode, show:

- Conflicting files
- Standard instructions for manual resolution
- Commands to continue: `git add <file>`, `git rebase --continue`

## Error Handling

1. Already up to date: Report "Already up to date with $base_branch".
2. Unrelated histories: Suggest `--allow-unrelated-histories` only with explicit confirmation.
3. Merge conflicts: Guide through orchestrated resolution (see above).
4. Rebase in progress: Offer to continue, skip, or abort existing rebase.
5. Main worktree not found: Offer fallback to standard fetch-based rebase.
6. Main worktree pull failure: Offer reset, skip sync, or cancel options.
7. Agent failure: Fall back to manual resolution with guidance.
