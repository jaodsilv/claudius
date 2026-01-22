---
description: Merges base branch into current branch when syncing with upstream. Use for incorporating main branch changes.
argument-hint: "[--base branch] [--no-stash]"
allowed-tools: Task, AskUserQuestion, Skill(gitx:rebasing-and-merging:*), Skill(gitx:orchestrating-conflict-resolution:*)
model: sonnet
---

# Merge Branch

Merges base branch into current branch using script-first architecture with LLM fallback for conflicts.

## Parse Arguments

From $ARGUMENTS, extract:

- `--base <branch>`: Base branch to merge from
- `--no-stash`: Fail if working tree is dirty

## Execute Script

Use `gitx:rebasing-and-merging` skill to perform merge:

- operation: merge
- base: `$base` (if provided)
- noStash: (if `--no-stash` flag is set)

## Handle Result

Parse the skill output and check result:

### Exit 0 (Success)

Report success:

```markdown
## Merge Complete

- Merged: [base] into [feature]
- Commits processed: [commits_processed]
- Stashed: [stashed]
- New HEAD: `git rev-parse --short HEAD`
```

### Exit 1 (Conflicts)

Conflicts detected. Use Skill `gitx:orchestrating-conflict-resolution` to handle:

1. Launch conflict-analyzer agent
2. Launch resolution-suggester agent
3. Present options to user
4. Validate resolutions
5. Commit merge with `git commit`

After resolution, report results.

### Exit 2 (Error)

Report error and suggest manual fix:

- `dirty_worktree`: "Commit or stash changes first, or use `--no-stash` to disable auto-stash"
- `fetch_failed`: "Check network connection and try again"
- `base_not_found`: "Base branch doesn't exist. Use `--base` to specify"
- Other: Show error message from script
