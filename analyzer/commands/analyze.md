---
description: >-
  Analyzes any input text (review comment, CI log, error, task description)
  to produce a structured analysis with root causes and severity-ordered findings.
  Use when needing to understand what is wrong and why before planning a fix.
argument-hint: "[--worktree <worktree>] [--input-type <type>] [<input-text>]"
allowed-tools: Task
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Task tool to run the `analyzer:issue-analyzer` agent with the prompt:

```
<worktree>$worktree</worktree>
$ARGUMENTS
```

## Step 2: Return Results

Parse the agent output for:
- `<analysis-path>`: path to the full analysis
- `<summary-path>`: path to the compact summary
- `<num-findings>`: number of findings

Report these to the user.
