---
name: gitx:rebasing-and-merging
description: >-
  Performs rebase or merge operations with auto-stash and conflict detection.
  Use when rebasing or merging branches with deterministic workflow and LLM
  fallback only for conflict resolution.
allowed-tools: Bash(scripts/rebase-merge-common.sh:*)
model: sonnet
---

# Rebase/Merge Common Operations

Deterministic script for rebase and merge operations with conflict detection.

## Usage

```bash
scripts/rebase-merge-common.sh <mode> [options]
```

## Arguments

- `mode`: Required. Either `rebase` or `merge`
- `--base <branch>`: Base branch to rebase/merge onto (default: default branch)
- `--no-stash`: Fail if working tree is dirty instead of auto-stashing
- `--force`: Skip confirmation prompts
- `--worktree <path>`: Worktree path to operate in (default: current directory)

## Exit Codes & Handling

### Exit 0 (Success)

Report to user:

- "Rebased/Merged {commits_processed} commits onto {base}"
- If `stashed: true`: "Local changes were stashed and restored"

### Exit 1 (Conflicts)

Pass `conflict_files[]` to `gitx:orchestrating-conflict-resolution` skill.

If `stashed: true`: remind user that local changes were stashed and will need to be restored after resolution.

### Exit 2 (Error)

Report `{error}: {message}`. Common errors:

- `dirty_worktree`: Working tree has uncommitted changes (use `--no-stash` to fail fast)
- `fetch_failed`: Network issue fetching from origin
- `base_not_found`: Invalid base branch specified

## Examples

```bash
# Basic rebase
scripts/rebase-merge-common.sh rebase --base main

# Merge with explicit base
scripts/rebase-merge-common.sh merge --base develop
```

See [references/extra-examples.md](references/extra-examples.md) for more scenarios.
