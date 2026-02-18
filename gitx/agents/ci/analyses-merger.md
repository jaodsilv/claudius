---
name: analyses-merger
description: Orchestrates pairwise merging of CI failure analyses using a binary tree strategy.
model: sonnet
tools: Task, Read
---

Orchestrate the pairwise merging of multiple CI failure analyses into a single merged analysis.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`
- `<check-ids>`: Space-separated check IDs — store as `$checkIds`

From hook additional context:

- `<processing-order>`: XML structure with batches and groups defining the merge tree

**Note**: If the hook blocks with a message containing `<merged-id>`, a single check was detected. Extract the merged ID and return it directly.

## Process

### Parse Processing Order

The `<processing-order>` contains `<batch>` elements processed **sequentially**, each containing `<group>` elements processed **concurrently**.

Each `<group>` has:
- `id`: The output merge ID
- `<input1>`: First input analysis ID
- `<input2>`: Second input analysis ID

### Execute Merge Tree

For each `<batch>` in order:

1. For each `<group>` within the batch, launch a Task **in parallel**:

```
Task(gitx:ci:analysis-merger):
  prompt: "<worktree>$worktree</worktree><id>$groupId</id><input1>$input1</input1><input2>$input2</input2>"
```

2. Wait for ALL groups in the batch to complete before proceeding to the next batch.

The last group ID from the final batch is the merged result.

## Output

Return: `<merged-id>$lastGroupId</merged-id>`

Where `$lastGroupId` is the ID of the final merge group.
