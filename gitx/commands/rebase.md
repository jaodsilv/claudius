---
description: Rebases current branch onto base branch when syncing with upstream. Use for maintaining linear history on feature branches.
argument-hint: "[--base branch]"
allowed-tools: Bash(git rebase:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git add:*), Bash(git stash:*), Bash(git pull:*), Bash(pwd:*), Bash(cd:*), Bash(test:*), Task, Read, AskUserQuestion, TodoWrite
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
git log --oneline $base_branch..HEAD 2>/dev/null | head -20
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

Before fetching, ensure the main worktree has latest changes:

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

### Navigate and Sync

If main worktree exists:

1. **Navigate to main worktree**:

   ```bash
   echo "📂 Navigating to main worktree..."
   cd ../main/
   ```

2. **Check working directory status**:

   ```bash
   echo "🔍 Checking main worktree status..."
   git status --porcelain
   ```

3. **Stash uncommitted changes** (if working directory not clean):

   ```bash
   echo "💾 Stashing uncommitted changes in main worktree..."
   git stash push -m "gitx: rebase auto-stash $(date +%Y%m%d-%H%M%S)"
   ```

   Set flag: `$main_stash_created = true`

4. **Pull latest base branch**:

   ```bash
   echo "⬇️  Pulling latest $base_branch..."
   git pull --ff-only origin $base_branch
   ```

   If pull fails (non-fast-forward):

   - Use AskUserQuestion: "Main worktree cannot fast-forward. How to proceed?"
   - Options: "Reset to origin/$base_branch", "Skip sync", "Cancel rebase"
   - If Reset: `git reset --hard origin/$base_branch`
   - If Skip: Continue without sync
   - If Cancel: Return to feature worktree and exit

5. **Return to feature worktree**:

   ```bash
   echo "🔙 Returning to feature worktree..."
   cd $original_dir
   ```

### Verify Sync

Verify main worktree is up to date:

```bash
echo "✅ Verifying main worktree sync..."
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

### Phase 1: Conflict Analysis

Get conflict status:

```bash
git status --porcelain | grep "^UU\|^AA\|^DD"
git diff --name-only --diff-filter=U
```

Launch conflict analyzer for comprehensive analysis:

```text
Task (gitx:conflict-analyzer):
  Operation: rebase
  Base Branch: $base_branch
  Conflicting Files: [list from git status]

  Analyze each conflict:
  - What both sides changed
  - Why they conflict
  - Semantic vs syntactic conflict
  - Recommended resolution strategy
```

### Phase 2: Resolution Suggestions

Launch resolution suggester:

```text
Task (gitx:resolution-suggester):
  Conflict Analysis: [output from Phase 1]

  For each conflict:
  - Generate specific resolution code
  - Provide confidence level
  - Note verification steps
```

### Phase 3: User-Guided Resolution

For each conflict, present analysis and options:

```text
AskUserQuestion:
  Question: "Conflict in [file] at lines [X-Y]. How would you like to resolve?"
  Options:
  1. "Apply suggested resolution (Recommended)" - Use AI-suggested resolution
  2. "Keep ours" - Keep current branch version
  3. "Keep theirs" - Keep base branch version
  4. "Resolve manually" - Open for manual editing
  5. "Abort rebase" - Cancel entire rebase
```

Apply chosen resolution:

- **Suggested**: Apply the resolution code from suggester
- **Keep ours**: `git checkout --ours <file>`
- **Keep theirs**: `git checkout --theirs <file>`
- **Manual**: Show conflict markers, wait for user

After resolving each file:

```bash
git add <file>
```

### Phase 4: Validation

After all conflicts resolved, launch validator:

```text
Task (gitx:merge-validator):
  Resolved Files: [list]
  Operation: rebase

  Validate:
  - No remaining conflict markers
  - Syntax is valid
  - Types check (if applicable)
```

If validation fails:

- Report issues
- Allow fixing before continuing

### Phase 5: Continue Rebase

When all conflicts resolved and validated:

```bash
git rebase --continue
```

If more conflicts occur (during subsequent commits):

- Repeat Phases 1-5

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

After successful rebase, restore any stashed changes in the main worktree:

```bash
if [ "$main_stash_created" = true ]; then
  echo "🔄 Restoring stashed changes in main worktree..."
  STASH_COUNT=$(git -C ../main/ stash list | grep "gitx: rebase" | wc -l)
  if [ "$STASH_COUNT" -gt 0 ]; then
    git -C ../main/ stash pop
    echo "✓ Stashed changes restored in main worktree"
  fi
else
  echo "✓ No stashed changes to restore in main worktree"
fi
```

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
