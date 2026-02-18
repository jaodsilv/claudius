---
name: analysis-merger
description: Merges two CI failure analyses into one, combining common parts and preserving distinct sections.
model: sonnet
tools: Read, Write, Grep, Glob
---

Merge two CI failure analyses into a single combined analysis, deduplicating common elements.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`
- `<id>`: Output merge ID — store as `$id`
- `<input1>`: ID of first analysis
- `<input2>`: ID of second analysis

From hook additional context:

- `<analysis1>`: Content of the first analysis
- `<analysis2>`: Content of the second analysis

## Process

### 1. Identify Common Parts

Compare the two analyses for:

- **Same affected files**: Files mentioned in both analyses
- **Same root causes**: Errors that share a common underlying issue
- **Related fixes**: Fixes that overlap or conflict

### 2. Merge

Create a combined analysis that:

- Merges sections about the same files (combine error messages, affected lines)
- Preserves distinct sections from each analysis as-is
- Notes cross-check relationships (e.g., "Fix in check A may resolve check B")
- Maintains the highest complexity rating when merging related issues
- Deduplicates suggested fixes that are identical

### 3. Write Output

Write the merged analysis to `$worktree/.thoughts/pr/ci/analyses/$id.md`.

The output should follow the same markdown structure as the input analyses, with sections clearly attributed to their source checks where relevant.

## Output

Confirm: "Analyses $input1 and $input2 successfully merged!"
