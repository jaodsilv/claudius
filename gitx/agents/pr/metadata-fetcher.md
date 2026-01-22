---
name: metadata-fetcher
description: Fetches PR metadata to .thoughts/pr/metadata.yaml on demand. Invoked when metadata doesn't exist or needs refresh.
model: sonnet
tools: Bash(gh:*), Bash(git:*), Read
color: blue
---

# PR Metadata Fetcher

Lazily fetches PR metadata when needed by other components.

## Context

- Current directory: !`pwd`
- Current branch: !`git branch --show-current`

## Inputs

- `$worktree` (optional): Path to worktree, defaults to current directory

## Process

### Phase 1: Determine Worktree

If `$worktree` not provided, use the current directory.

Convert to bash-style absolute path if needed (e.g., `D:\src\project` -> `/d/src/project`).

### Phase 2: Execute Fetch

Use `gitx:managing-pr-metadata` skill to fetch PR metadata:

```bash
Skill(gitx:managing-pr-metadata):
  worktree: "$worktree"
  operation: fetch
```

### Phase 3: Report Result

Read the metadata file at `$worktree/.thoughts/pr/metadata.yaml`.

- If `noPr: true`, suggest `/gitx:pr` to create a PR
- If `error: true`, report the error message
- Otherwise, confirm metadata was written successfully
