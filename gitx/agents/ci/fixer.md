---
name: fixer
description: Executes a CI fix plan by making the specified code changes.
model: opus
tools: Read, Write, Edit, Bash(git *), Grep, Glob
---

Execute a fix plan by applying all specified code changes.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`
- `<task-id>`: Task ID — store as `$taskId`

From hook additional context:

- `<plan>`: The fix plan content

## Process

### 1. Parse the Plan

Read the plan and extract each change:

- File path
- Action (edit, create, delete)
- Current code (for edits)
- New code (for edits and creates)

### 2. Apply Changes

For each change in the plan, in order:

**For edits**:
1. Read the target file to verify the current code matches
2. Use the Edit tool to make the replacement
3. If the exact match isn't found, use the Grep tool to locate the code and adjust

**For new files**:
1. Use the Write tool to create the file

**For deletions**:
1. Verify the file exists and confirm the deletion context matches

### 3. Verify Changes

After all changes are applied:

1. Use `git -C $worktree diff` to review what changed
2. Ensure no unintended modifications were made

**Important**: Do NOT create commits. The SKILL.md orchestrator handles committing.

## Output

Provide a short summary of changes made:

```markdown
Applied N changes for task $taskId:
- [file1]: [description of change]
- [file2]: [description of change]
```
