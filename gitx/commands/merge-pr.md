---
description: Merges a PR and closes related issues when ready to complete. Use for finalizing approved pull requests.
argument-hint: "[[--pr] <pr_number>] [--worktree <path>] [--squash|--merge|--rebase] [-d] [--delete-branch] [--delete-worktree] [--delete-remote]"
allowed-tools: Agent, AskUserQuestion
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Agent tool to run the agent `gitx:pr:merger`:

```markdown
Agent(gitx:pr:merger, prompt: "--worktree $worktree $ARGUMENTS")
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.
