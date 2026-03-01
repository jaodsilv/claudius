---
description: >-
  Challenges any input (analysis, review comment, request, proposal) as devil's
  advocate, stress-testing assumptions and finding blind spots. Use when critical
  review of any output is needed before acting on it.
argument-hint: "[--worktree <worktree>] [--input-path <path>] [<input-text>]"
allowed-tools: Task
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Agent tool to run the `analyzer:adversarial-critic` agent with the prompt:

```
<worktree>$worktree</worktree>
$ARGUMENTS
```

## Step 2: Return Results

Parse the agent output for:
- `<critique-path>`: path to the full critique
- `<verdict>`: Strong, Moderate, or Weak
- `<must-address-count>`: number of must-address issues

Report the verdict and critique path to the user.
