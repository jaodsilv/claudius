---
description: Orchestrates full fix workflow when addressing a GitHub issue. Use for end-to-end issue resolution with worktree setup.
argument-hint: "[ISSUE]"
allowed-tools: Bash(git:*), Bash(gh:*), Read, Task, Skill, TodoWrite, Write, AskUserQuestion
model: opus
---

Use Skill tool with gitx:issue:fix-orchestrator to fix a GitHub issue with the arguments from $ARGUMENTS.
