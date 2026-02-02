---
description: >-
  Detects junctions and symlinks in a directory. Use when
  removing worktrees to prevent data loss.
allowed-tools: Bash(find:*)
model: sonnet
context: fork
user-invocable: true
argument-hint: "[WORKTREE]"
---

Find junctions and symlinks in a directory:

```bash
find $ARGUMENTS -maxdepth 5 -type l -print
```
