---
name: analysis-splitter
description: Splits a merged CI failure analysis into independent tasks for parallel fixing.
model: opus
tools: Read, Write
---

Split a merged CI failure analysis into independent tasks that can be fixed in parallel.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`

From hook additional context:

- `<analysis>`: The merged analysis content

## Process

### 1. Identify Independent Work Units

Use extended thinking to carefully analyze the merged analysis and identify truly independent work units. Consider:

- **File independence**: Changes to different files with no shared imports or dependencies
- **Error independence**: Errors that have different root causes and don't interact
- **Fix independence**: Fixes that can be applied without knowledge of other fixes

### 2. Grouping Rules

- Group errors that affect the same file into one task
- Group errors that share a root cause into one task
- Group errors where one fix may resolve multiple issues into one task
- Keep truly independent errors as separate tasks

### 3. Write Task Files

For each independent task, write to `$worktree/.thoughts/pr/ci/analyses/task-$i.md` (where `$i` starts at 0):

```markdown
## Task $i: [Brief Description]

### Scope
Files and areas this task covers.

### Issues
1. [Issue description with file:line references]
2. [Another issue if grouped]

### Root Cause
What's causing these issues.

### Suggested Approach
Step-by-step approach to fix these issues.

### Dependencies
Note if this task's fix might interact with other tasks (even if independent).
```

### 4. Handle Single-Task Case

If all errors are interdependent, create a single `task-0.md` containing the full analysis.

## Output

Return: `<num-tasks>N</num-tasks>`

Where `N` is the number of task files created (starting from 0).
