---
description: >-
  Splits a structured analysis file into independent task files for parallel
  planning. Use after analyzing an issue when the analysis contains multiple
  independent work units.
argument-hint: "[--worktree <worktree>] [--analysis-path <path>]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Determine Analysis Path

Extract `--analysis-path` from $ARGUMENTS if provided. If not provided, default to:
`$worktree/.thoughts/analyzer/full-analysis.md`

## Step 2: Run Agent

Use the Agent tool to spawn the agent `analyzer:analysis-splitter` to split the analysis:

```markdown
Agent(analyzer:analysis-splitter):
  prompt:
    <worktree>$worktree</worktree>
    <analysis-path>$analysisPath</analysis-path>
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed.

## Step 3: Return Results

Parse the agent output for `<num-tasks>` — the number of task files created.

Report the task count and directory (`$worktree/.thoughts/analyzer/tasks/`) to the user.
