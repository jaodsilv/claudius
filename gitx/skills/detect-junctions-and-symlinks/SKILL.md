---
name: gitx:detect-junctions-and-symlinks
description: >-
  Detects junctions and symlinks in a directory. Use when
  removing worktrees to prevent data loss.
version: 1.0.0
allowed-tools: Bash(find:*)
model: haiku
---

Find junctions and symlinks in a directory:

```bash
find $worktreePath -maxdepth 5 -type l -print
```
