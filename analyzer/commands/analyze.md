---
description: >-
  Analyzes any input text (review comment, CI log, error, task description)
  to produce a structured analysis with root causes and severity-ordered findings.
  Use when needing to understand what is wrong and why before planning a fix.
argument-hint: "[--worktree <worktree>] [--input-type <type>] [<input-text>]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Run Agent

Use the Agent tool to spawn the agent `analyzer:issue-analyzer` to analyze the input:

```markdown
Agent(analyzer:issue-analyzer):
  prompt:
    <worktree>$worktree</worktree>
    $ARGUMENTS
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Step 2: Return Results

Parse the agent output for:
- `<analysis-path>`: path to the full analysis
- `<summary-path>`: path to the compact summary
- `<num-findings>`: number of findings

Report these to the user.
