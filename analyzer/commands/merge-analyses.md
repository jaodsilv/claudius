---
description: >-
  Merges multiple analysis files into a single consolidated analysis, handling
  overlaps and contradictions. Use when combining analyses from different sources.
argument-hint: "[--worktree <worktree>] --analysis-paths <path1> <path2> [<path3> ...]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Step 1: Extract Analysis Paths

Extract the `--analysis-paths` value(s) from $ARGUMENTS. At least 2 paths are required.

## Step 2: Run Agent

Use the Agent tool to run the `analyzer:analyses-merger` agent with the prompt:

```
<worktree>$worktree</worktree>
<analysis-paths>$analysisPaths</analysis-paths>
```

## Step 3: Return Results

Parse the agent output for:
- `<merged-path>`: path to the merged analysis
- `<summary-path>`: path to the merged summary
- `<num-findings>`: total findings after merge
- `<num-conflicts>`: number of conflicts between sources

Report the merged analysis path and summary to the user.
