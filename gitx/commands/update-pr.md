---
description: Updates PR title and description when changes have evolved. Use for refreshing outdated PR content.
argument-hint: "[--worktree <worktree>] [--no-metadata-sync]"
allowed-tools: Agent
model: sonnet
---

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument and its value from $ARGUMENTS if present.

## Modes

Extract from $ARGUMENTS:

- **No metadata sync (--no-metadata-sync)**: If `--no-metadata-sync` is present,
  skip all automatic metadata.yaml writes and refreshes. Identified as
  `$NO_METADATA_SYNC="true"` if present, otherwise `"false"`.

## Step 1: Run Agent

Use the Agent tool to run the `gitx:pr:updater` agent with the prompt below.
Pass `$ARGUMENTS` through unchanged so that `--no-metadata-sync` (when present) flows down to the agent.

```markdown
<worktree>$worktree</worktree>
$ARGUMENTS
```
