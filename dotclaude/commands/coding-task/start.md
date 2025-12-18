---

allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, TodoWrite, Skill, SlashCommand
description: Start a coding task with TDD workflow orchestration
argument-hint: task-description

---

## Context

- Arguments: <arguments>$ARGUMENTS</arguments>
- Purpose: <purpose>Initialize and orchestrate a coding task following TDD principles using the coding-task-orchestrator agent.</purpose>

## Execution

Follow the instructions below:

1. Parse the task description from arguments
2. If no task description provided, ask user for it
3. Launch the `coding-task-orchestrator` agent with the task description

### Step 1: Validate Arguments

If `$ARGUMENTS` is empty or unclear:

```text
Ask user: "What coding task would you like to work on? Please describe the feature, bug fix, or refactoring."
```

### Step 2: Launch Orchestrator Agent

Use the Task tool to launch the coding-task-orchestrator agent:

```text
Task tool parameters:
- subagent_type: "coding-task-orchestrator" (if registered) OR "general-purpose"
- prompt: See template below
- description: "Orchestrate coding task"
```

### Template Prompt for Task Tool

```markdown
## Coding Task Request

**Task Description**: {{task-description}}

## Instructions

You are the coding-task-orchestrator. Execute the complete TDD workflow for this task:

1. **Phase 0**: Create git worktree for isolated development
2. **Phase 1**: Evaluate if tests are needed
3. **Phase 2**: Select TDD approach using `@tdd-approach-selection` skill:
   - Full cycle for standard tasks
   - Individual phases for complex tasks
4. **Phase 3**: Verify design-code alignment
5. **Phase 4**: Create conventional commit
6. **Phase 5**: Evaluate refactoring needs (optional if full cycle used)
7. **Phase 6**: Create/manage PR
8. **Phase 7**: Close task and cleanup

Use `/compact` after each major phase to manage context.

Reference documentation:
- @dotclaude/shared/coding-task-workflow.md
- @dotclaude/skills/tdd-approach-selection/SKILL.md
- @dotclaude/skills/tdd-workflow/SKILL.md
```

## Parameters

### Parameters Schema

```yaml
coding-task-start-arguments:
  type: object
  description: Arguments for the command /coding-task:start
  properties:
    task-description:
      type: string
      description: Description of the coding task (feature, bug fix, refactoring)
  required:
    - task-description
```

## Usage Examples

### Start a new feature

```text
/coding-task:start Add user authentication with JWT tokens
```

### Start a bug fix

```text
/coding-task:start Fix race condition in payment processor
```

### Start a refactoring task

```text
/coding-task:start Refactor user service to use repository pattern
```

### Interactive start (no arguments)

```text
/coding-task:start
```

Will prompt for task description.

## Related Skills

| Skill                    | Purpose                  |
|--------------------------|--------------------------|
| `tdd-approach-selection` | Choose TDD approach      |
| `tdd-workflow`           | TDD principles & phases  |
| `conventional-commits`   | Commit message format    |
| `conventional-branch`    | Branch naming conventions|

## Related Commands

| Command             | Purpose                           |
|---------------------|-----------------------------------|
| `/project:create`   | Create new project with data repo |
