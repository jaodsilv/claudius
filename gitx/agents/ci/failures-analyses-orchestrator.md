---
name: failures-analyses-orchestrator
description: Orchestrates per-check CI failure analysis, merging, and splitting into independent tasks.
model: sonnet
tools: Agent, Read, TaskCreate, TaskGet, TaskList, TaskUpdate
---

Orchestrate the full CI failure analysis pipeline: analyze each check, merge analyses, split into independent tasks.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`
- `<check-ids>`: Space-separated sequential check IDs — store as `$checkIds`

## Process

### Initialize Progress Tracking

Use the TaskCreate tool to add the following task(s) to the task list:

<new-tasks>
- [ ] Analyze individual check failures
- [ ] Merge analyses
- [ ] Split into independent tasks
</new-tasks>

### Step 1: Analyze Each Check Failure

Mark "Analyze individual check failures" as in_progress.

Parse `$checkIds` into individual IDs. For each check ID, launch an Agent **in parallel**:

```markdown
Agent(gitx:ci:failure-analyzer):
  prompt: "<worktree>$worktree</worktree><check-id>$id</check-id>"
```

Wait for ALL analyzers to complete.

Mark "Analyze individual check failures" as completed.

### Step 2: Merge Analyses

Mark "Merge analyses" as in_progress.

Launch the analyses merger:

```markdown
Agent(gitx:ci:analyses-merger):
  prompt: "<worktree>$worktree</worktree><check-ids>$checkIds</check-ids>"
```

Parse the result for `<merged-id>` — store as `$mergedId`.

Mark "Merge analyses" as completed.

### Step 3: Split into Independent Tasks

Mark "Split into independent tasks" as in_progress.

Launch the analysis splitter:

```markdown
Agent(gitx:ci:analysis-splitter):
  prompt: "<worktree>$worktree</worktree><analysis-id>$mergedId</analysis-id>"
```

Parse the result for `<num-tasks>` — store as `$numTasks`.

Mark "Split into independent tasks" as completed.

## Output

Return: `<num-tasks>$numTasks</num-tasks>`
