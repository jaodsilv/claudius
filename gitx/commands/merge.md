---
description: Merges base branch into current branch when syncing with upstream. Use for incorporating main branch changes.
argument-hint: "[--base branch]"
allowed-tools: Bash(git merge:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Task, Read, AskUserQuestion, TodoWrite
---

# Merge Branch (Orchestrated)

Merge a base branch into the current branch to incorporate upstream changes. Uses multi-agent orchestration for conflict resolution.

## Parse Arguments

From $ARGUMENTS, extract:

- `--base <branch>`: Branch to merge from (default: main)

## Gather Context

Get repository state:

- Current branch: !`git branch --show-current`
- Main branch: !`ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && echo "${ref#refs/remotes/origin/}" || echo "main"`
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

## Handle Conflicts (Orchestrated)

If conflicts occur (`git merge` reports conflicts):

### Phase 1: Conflict Analysis

Get conflict status:

```bash
git status --porcelain | grep "^UU\|^AA\|^DD"
git diff --name-only --diff-filter=U
```

Launch conflict analyzer for comprehensive analysis:

```text
Task (gitx:conflict-analyzer):
  Operation: merge
  Base Branch: [base-branch]
  Current Branch: [current-branch]
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
  3. "Keep theirs" - Keep incoming branch version
  4. "Resolve manually" - Open for manual editing
  5. "Abort merge" - Cancel entire merge
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
  Operation: merge

  Validate:
  - No remaining conflict markers
  - Syntax is valid
  - Types check (if applicable)
```

If validation fails:

- Report issues
- Allow fixing before continuing

### Phase 5: Complete Merge

When all conflicts resolved and validated:

```bash
# Create merge commit
git commit -m "Merge [base-branch] into [current-branch]

Resolved conflicts:
- [file1.ts]: [resolution summary]
- [file2.ts]: [resolution summary]
"
```

## Pop Stash

If changes were stashed:

- `git stash pop`
- Report any conflicts with stash

## Report Results

Show merge outcome:

```markdown
## Merge Complete

### Summary
- Merged: [base] into [current]
- Commits incorporated: [count]
- Conflicts resolved: [count]
- Merge commit: [hash] (if not fast-forward)

### Resolution Summary
- [file1.ts]: [resolution applied]
- [file2.ts]: [resolution applied]

### Changes Incorporated
[summary of changes from base branch]

### Next Steps
- Run tests to verify: `npm run test`
- Push with: `git push`
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

- Conflicting files with markers
- Standard instructions for manual resolution
- Commands to continue: `git add <file>`, `git commit`

## Error Handling

1. Already up to date: Report "Already up to date with <base>".
2. Merge conflicts: Guide through orchestrated resolution (see above).
3. Merge in progress: Offer to continue or abort existing merge.
4. Agent failure: Fall back to manual resolution with guidance.
