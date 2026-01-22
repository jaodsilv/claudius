---
name: gitx:detecting-junctions-and-symlinks
description: >-
  Detects junctions and symlinks in a directory. Use when
  removing worktrees to prevent data loss.
allowed-tools: Bash(find:*)
model: sonnet
---

Find junctions and symlinks in a directory:

```bash
find $worktreePath -maxdepth 5 -type l -print
```
