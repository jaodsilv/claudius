---
name: gitx:getting-default-branch
description: >-
  Gets the default branch name and path from the git worktree list.
allowed-tools: Bash(scripts/get-default-branch.sh)
model: sonnet
---

# Getting Default Branch

Gets the default branch name and its worktree path.

## Usage

```bash
scripts/get-default-branch.sh
```

## Output

Returns YAML with branch info:

```yaml
defaultBranch: main
defaultBranchPath: /d/src/project/main
```

If no dedicated worktree exists for the default branch:

```yaml
defaultBranch: main
defaultBranchPath: null
```
