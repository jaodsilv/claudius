---

description: Merges base branch into current branch when syncing with upstream. Use for incorporating main branch changes.
argument-hint: "[--base branch]"
allowed-tools: Bash(git merge:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Task, Read, AskUserQuestion, TodoWrite, Skill(gitx:orchestrating-conflict-resolution)
model: opus
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

Use Skill tool with gitx:orchestrating-conflict-resolution. The skill handles:

1. **Phase 1**: Launch conflict-analyzer agent for comprehensive analysis
2. **Phase 2**: Launch resolution-suggester agent for resolution code
3. **Phase 3**: User-guided resolution with 5 options (see skill for details)
4. **Phase 4**: Launch merge-validator agent for validation
5. **Phase 5**: Create merge commit with resolution summary

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
