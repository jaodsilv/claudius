---
description: Responds to CI failures with multi-agent analysis, planning, and automated fixes.
argument-hint: "[--worktree <worktree>] [--repo <owner/name>] [--pr <number>] [--ci-mode <job-name>] [--no-metadata-sync]"
allowed-tools: Agent, Skill
model: sonnet
---

# Address CI Failures - Multi-Agent Pipeline

## Step 0: Parse Hook Context

Parse input from hook additional context looking for the XML tags:

- `<worktree>`: store its value in `$worktree` (may be absent in foreign-PR mode)
- `<repo>`: store its value in `$repo` (present when --repo/--pr were used)
- `<pr-number>`: store its value in `$prNumber` (present when --repo/--pr were used)
- `<check-ids>`: store its value in `$checkIds` (space-separated sequential IDs like "0 1 2")
- `<ci-mode>`: store its value in `$ciMode` (present when --ci-mode was used; names the CI job we are running inside)

Ignore any $ARGUMENTS — all input comes from hook context.

## Modes

Extract from $ARGUMENTS:

- **No metadata sync (--no-metadata-sync)**: If `--no-metadata-sync` is present,
  skip all automatic metadata.yaml writes and refreshes. Identified as
  `$NO_METADATA_SYNC="true"` if present, otherwise `"false"`.

When forwarding control to downstream skills (Step 4), append `--no-metadata-sync`
if `$NO_METADATA_SYNC` is `"true"`.

> **Note**: When `<repo>`/`<pr-number>` are present without `<worktree>`, downstream agents
> (`gitx:ci:failures-analyses-orchestrator` and below) currently expect a local worktree —
> full foreign-PR execution is future work.

## Step 1: Analyze CI Failures

Use the Agent tool to run the `gitx:ci:failures-analyses-orchestrator` agent:

```markdown
Agent(gitx:ci:failures-analyses-orchestrator):
  prompt: "<worktree>$worktree</worktree><check-ids>$checkIds</check-ids>"
```

Parse the result for `<num-tasks>` — store as `$numTasks`.

If `$numTasks` is 0, report "No actionable CI failures found" and stop.

## Step 2: Plan Fixes (parallel)

For each task index `$i` from 0 to `$numTasks - 1`, launch an Agent **in parallel**:

```markdown
Agent(gitx:ci:fix-planner):
  prompt: "<worktree>$worktree</worktree><task-id>$i</task-id>"
```

Store a mapping of agentId to taskId for each launched planner.

<!-- Wait for ALL planners to complete. -->

## Step 3: Execute Fixes

For each completed fix-planner, using its stored `$taskId`, launch an Agent for the fixer:

```markdown
Agent(gitx:ci:fixer):
  prompt: "<worktree>$worktree</worktree><task-id>$taskId</task-id>"
```

**Important**: If multiple fixers would touch overlapping files, run them sequentially to avoid conflicts. Otherwise, run them in parallel.

Wait for ALL fixers to complete. Collect their output summaries.

## Step 4: Commit and Push

Use the Skill tool to execute the skill `/gitx:commit-push`. If `$NO_METADATA_SYNC`
is `"true"`, append `--no-metadata-sync` to the args:

```markdown
Skill(/gitx:commit-push, args: "--worktree $worktree")
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
```
