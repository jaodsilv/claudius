---
name: analysis-splitter
description: >-
  Splits a structured analysis into independent task files for parallel
  planning and fixing. Use when an analysis needs decomposition into
  independent work units.
model: opus
tools: Read, Write
color: green
---

Split a structured analysis into independent tasks that can be planned and fixed in parallel.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`

From hook additional context:

- `<analysis>`: The analysis content to split

## Process

### 1. Identify Independent Work Units

Use extended thinking to carefully analyze the content and identify truly independent work units. Consider:

- **File independence**: Changes to different files with no shared imports or dependencies
- **Error independence**: Errors that have different root causes and don't interact
- **Fix independence**: Fixes that can be applied without knowledge of other fixes

### 2. Grouping Rules

- Group findings that affect the same file into one task
- Group findings that share a root cause into one task
- Group findings where one fix may resolve multiple issues into one task
- Keep truly independent findings as separate tasks

### 3. Write Task Files

For each independent task, write to `$worktree/.thoughts/analyzer/tasks/task-$i.md` (where `$i` starts at 0):

```markdown
## Task $i: [Brief Description]

### Metadata
- **Severity**: critical|high|medium|low
- **Effort**: trivial|minor|moderate|significant
- **Files**: [list of affected files]

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

If all findings are interdependent, create a single `task-0.md` containing the full analysis reformatted as a task.

## Output

Return: `<num-tasks>N</num-tasks>`

Where `N` is the number of task files created (starting from 0).
