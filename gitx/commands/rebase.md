---
description: Rebase current branch onto base branch (default: main)
argument-hint: "[--base branch]"
allowed-tools: Bash(git rebase:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*), Bash(git add:*), Task, Read, AskUserQuestion
---

# Rebase Branch (Orchestrated)

Rebase the current branch onto a base branch to incorporate upstream changes and maintain a linear history. Uses multi-agent orchestration for conflict resolution.

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

## Handle Conflicts (Orchestrated)

If conflicts occur (`git rebase` exits with conflicts):

### Phase 1: Conflict Analysis

Get conflict status:
```bash
git status --porcelain | grep "^UU\|^AA\|^DD"
git diff --name-only --diff-filter=U
```

Launch conflict analyzer for comprehensive analysis:
```
Task (gitx:conflict-analyzer):
  Operation: rebase
  Base Branch: [base-branch]
  Conflicting Files: [list from git status]

  Analyze each conflict:
  - What both sides changed
  - Why they conflict
  - Semantic vs syntactic conflict
  - Recommended resolution strategy
```

### Phase 2: Resolution Suggestions

Launch resolution suggester:
```
Task (gitx:resolution-suggester):
  Conflict Analysis: [output from Phase 1]

  For each conflict:
  - Generate specific resolution code
  - Provide confidence level
  - Note verification steps
```

### Phase 3: User-Guided Resolution

For each conflict, present analysis and options:

```
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
```
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
- Rebased: [count] commits onto [base]
- Conflicts resolved: [count]
- New HEAD: [commit hash]

### Resolution Summary
- [file1.ts]: [resolution applied]
- [file2.ts]: [resolution applied]

### Next Steps
- Run tests to verify: `npm run test`
- Push with: `git push --force-with-lease` (if previously pushed)
```

## Fallback Mode

If orchestrated conflict resolution fails:
```
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

- Already up to date: Report "Already up to date with <base>"
- Unrelated histories: Suggest `--allow-unrelated-histories` only with explicit confirmation
- Merge conflicts: Guide through orchestrated resolution (see above)
- Rebase in progress: Offer to continue, skip, or abort existing rebase
- Agent failure: Fall back to manual resolution with guidance
