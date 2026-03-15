---
description: Responds to PR review comments when feedback needs addressing. Use for iterating on pull request feedback.
argument-hint: "[--worktree <worktree>] [--resolve-level <all|critical|important>] [-f or --force] [[--review-comment] <review-comment>]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Agent tool to spawn the agent `gitx:address-review:review-responder`:

```markdown
Agent(gitx:address-review:review-responder):
  prompt:
    <worktree>$worktree</worktree>
    $ARGUMENTS
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.
