---
description: Comprehensive PR review using specialized agents. Requires pr-review-toolkit@claude-plugins-official.
argument-hint: "[worktree]"
allowed-tools: Skill(gitx:reviewing-prs:*)
context: fork
model: sonnet
---

If $ARGUMENTS is empty:

- Invoke the skill `gitx:reviewing-prs` with the Skill tool.

Otherwise:

- Invoke the skill `gitx:reviewing-prs $1` with the Skill tool.
