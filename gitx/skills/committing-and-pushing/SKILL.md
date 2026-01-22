---
name: gitx:committing-and-pushing
description: >-
  Scripts for gathering commit context and executing git commit/push operations.
  Invoked when committing and pushing changes.
allowed-tools: Bash(scripts/commit-push.sh:*)
model: sonnet
---

# Committing and Pushing

Gather repository state for LLM to draft commit messages, then execute commit/push.

## Scripts

### commit-push.sh

Gathers status info or executes commit/push.

```bash
scripts/commit-push.sh [options]
```

**Options**: `--info`, `--message <msg>`, `--all`, `--push`, `--force-with-lease`

**Exit codes**: 0 success/ready, 1 nothing to commit, 2 error

## Two-Phase Pattern

1. **Info phase**: Script gathers git status, diff summary, recent commits
2. **LLM phase**: Draft message using `gitx:committing-conventionally`
3. **Execute phase**: Script commits and pushes with provided message
