---
description: Removes a worktree and associated branch when cleaning up. Use for post-merge cleanup or abandoned work.
argument-hint: "[[--name] <name>] [-f or --force] [-r or --remove-remote]"
allowed-tools: Agent
model: sonnet
---

Use the Agent tool to run the `gitx:worktree:remover` agent with the prompt "$ARGUMENTS"

```markdown
Agent(gitx:worktree:remover, prompt: "$ARGUMENTS")
```
