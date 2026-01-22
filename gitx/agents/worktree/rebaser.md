---
name: rebaser
description: Rebases current branch onto base branch when syncing with upstream. Use for maintaining linear history on feature branches.
tools: Bash(git rebase:*), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Task, AskUserQuestion, Skill
model: sonnet
---

# Rebase Branch (Script-First)

Thin wrapper that delegates to `rebase-merge-common.sh` script with LLM handling only for conflicts.

## Parse Arguments

From $ARGUMENTS, extract:

- `--base <branch>`: Base branch to rebase onto (store in `$base`)
- `--no-stash`: Fail if working tree is dirty (store as flag)
- `--worktree <path>`: Worktree path (store in `$worktree`, default: `.`)

## Execute Script

Use `gitx:rebasing-and-merging` skill to perform rebase:

- operation: rebase
- base: `$base` (if provided)
- noStash: (if `--no-stash` flag is set)
- worktree: `$worktree` (default: `.`)

## Handle Result

Parse the skill output and check result:

### Exit 0 (Success)

Report from JSON:

```markdown
## Rebase Complete

- Rebased: [commits_processed] commits onto [base]
- Branch: [feature]
- Stashed: [stashed]
- New HEAD: `git rev-parse --short HEAD`

### Next Steps
- Run tests to verify changes
- Push with: `git push --force-with-lease` (if previously pushed)
```

### Exit 1 (Conflicts)

Conflicts detected. Use Skill `gitx:orchestrating-conflict-resolution` to handle:

1. **Phase 1**: Launch conflict-analyzer agent
2. **Phase 2**: Launch resolution-suggester agent
3. **Phase 3**: User-guided resolution with options
4. **Phase 4**: Launch merge-validator agent
5. **Phase 5**: Continue rebase with `git rebase --continue`

After all conflicts resolved, report summary.

### Exit 2 (Error)

Report error based on JSON error code:

- `dirty_worktree`: "Working tree has uncommitted changes. Use `--no-stash` to see them, or commit/stash first."
- `fetch_failed`: "Failed to fetch from origin. Check network connection."
- `base_not_found`: "Base branch '[base]' not found. Use `--base` to specify a valid branch."
- `same_branch`: "Cannot rebase: already on the base branch."
- `detached_head`: "Cannot rebase: in detached HEAD state."
- Other: Show error message from script

## Fallback Mode

If conflict resolution skill fails:

```text
AskUserQuestion:
  Question: "Conflict resolution encountered an issue. How to proceed?"
  Options:
  1. "Resolve manually" - Show conflicting files and manual instructions
  2. "Retry" - Try orchestration again
  3. "Abort rebase" - Run `git rebase --abort`
```

For manual mode, show:

- Conflicting files: `git diff --name-only --diff-filter=U`
- Instructions: Edit files, `git add <file>`, `git rebase --continue`
