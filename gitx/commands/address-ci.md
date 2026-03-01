---
description: Responds to CI failures with multi-agent analysis, planning, and automated fixes.
argument-hint: "[--worktree <worktree>]"
allowed-tools: Agent, Skill
model: sonnet
---

# Address CI Failures - Multi-Agent Pipeline

## Step 0: Parse Hook Context

Parse input from hook additional context looking for the XML tags:

- `<worktree>`: store its value in `$worktree`
- `<check-ids>`: store its value in `$checkIds` (space-separated sequential IDs like "0 1 2")

Ignore any $ARGUMENTS — all input comes from hook context.

## Step 1: Analyze CI Failures

Use the Agent tool to run the `gitx:ci:failures-analyses-orchestrator` agent:

```
Agent(gitx:ci:failures-analyses-orchestrator):
  prompt: "<worktree>$worktree</worktree><check-ids>$checkIds</check-ids>"
```

Parse the result for `<num-tasks>` — store as `$numTasks`.

If `$numTasks` is 0, report "No actionable CI failures found" and stop.

## Step 2: Plan Fixes (parallel)

For each task index `$i` from 0 to `$numTasks - 1`, launch an Agent **in parallel**:

```
Agent(gitx:ci:fix-planner):
  prompt: "<worktree>$worktree</worktree><task-id>$i</task-id>"
```

Store a mapping of agentId to taskId for each launched planner.

Wait for ALL planners to complete.

## Step 3: Execute Fixes

For each completed fix-planner, using its stored `$taskId`, launch an Agent for the fixer:

```
Agent(gitx:ci:fixer):
  prompt: "<worktree>$worktree</worktree><task-id>$taskId</task-id>"
```

**Important**: If multiple fixers would touch overlapping files, run them sequentially to avoid conflicts. Otherwise, run them in parallel.

Wait for ALL fixers to complete. Collect their output summaries.

## Step 4: Commit and Push

Use the Skill tool to invoke `/gitx:commit-push`:

```
Skill(/gitx:commit-push):
  args: "--worktree $worktree"
```

## Step 5: Output Summary

Output a summary of what was done:

```markdown
## CI Fixes Applied

### Changes
- [Summary from each fixer]

### Commit
[Commit message from commit-push]

### Next Steps
- Wait for CI to re-run
- Use `/gitx:next-turn` to check status
```
