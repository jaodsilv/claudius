# Coding Task Workflow Process

> This workflow process **MUST** be followed for all coding tasks.
> It ensures consistent, high-quality development practices using Test-Driven Development (TDD) principles
> and multi-agent collaboration.

## Overview

This workflow is designed to be followed sequentially,
where each upper-level task must wait for the worker to finish before continuing with the next step.
The process leverages multiple specialized agents via the Task tool to ensure thorough testing, design, and implementation.

## Quick Reference

| Phase | Name                     | Key Action                              |
|-------|--------------------------|----------------------------------------|
| 0     | Initial Setup            | Create git worktree                    |
| 1     | Test Evaluation          | Determine if tests needed              |
| 2     | TDD Execution            | RED-GREEN-REFACTOR cycle               |
| 3     | Design Alignment         | Verify code follows design             |
| 4     | Commit                   | Create conventional commit             |
| 5     | Refactor                 | Evaluate improvement opportunities     |
| 6     | Pull Request             | Create/manage PR, handle reviews       |
| 7     | Close                    | Complete task and cleanup              |

## Workflow Process

### Phase 0: Initial Setup

**In the main agent**: Create a new git worktree for the task.

1. Create the worktree:

   ```bash
   git worktree add -b feature/task-name ../task-name-worktree
   ```

2. **Data Folder Setup**: Ask user if this worktree needs a data folder link.
   - If YES and `D:\src\{project-name}\data` exists:

     ```cmd
     mklink /J D:\src\{project-name}\{worktree-name}\data D:\src\{project-name}\data
     ```

   - If YES but data repo doesn't exist: Ask if user wants to create it (use `/project:create-data`)

3. Change to the new worktree:

   ```bash
   cd ../task-name-worktree
   ```

4. Memorize the worktree name for later steps.

### Phase 1: Test Requirement Evaluation

Create a new agent for the task using the Task tool to evaluate the need for tests:

1. **If it is a refactoring**: Evaluate if it needs new tests
2. **If it is a cleanup** or something that does not require new tests: Consider it does not need new tests
3. **If it is a bug fix or a new feature**: New tests are required

### Phase 2: TDD Approach Selection

Based on task complexity, choose the appropriate TDD approach using `@tdd-approach-selection` skill.

#### When to use Full Cycle (Phase 2A)

Use for:

1. Standard features with well-defined requirements
2. New modules or components with clear boundaries
3. Bug fixes where test coverage already exists
4. Tasks with straightforward test scenarios

#### When to use Individual Phases (Phase 2B)

Use for:

1. Complex tasks requiring iterative design exploration
2. Experimental or research-oriented development
3. Tasks where you need intervention between phases
4. Integration with existing complex test suites
5. Performance-critical code requiring custom optimization

---

### Phase 2A: Full Cycle Approach (Recommended for most tasks)

Follow `@tdd-workflow` skill for the complete TDD cycle:

1. Execute complete RED-GREEN-REFACTOR cycle:
   - Test specification and design
   - RED Phase: Write failing tests
   - GREEN Phase: Minimal implementation
   - REFACTOR Phase: Code quality improvements
   - Integration tests
   - Final review

2. [COMPACT: task, worktree, step]

3. Skip to Phase 3: Design Alignment Check

---

### Phase 2B: Individual Phases Approach (For complex tasks)

#### Phase 2B.1: Unit Tests (RED Phase)

**Agent Pattern**: Design → Review → Loop (max 3-5 iterations)

1. **Design Agent**: Identify test cases, edge cases, expected behavior
2. **Review Agent**: Validate completeness, check edge case coverage
3. Loop if needed
4. **Write Tests Agent**: Implement failing unit tests
5. **Review Agent**: Validate test quality
6. **GATE**: All tests must fail with meaningful errors
7. [COMPACT: task, worktree, unit test design, step]

#### Phase 2B.2: Solution Design

**Agent Pattern**: Design → Review → Loop (max 3-5 iterations)

1. **Design Agent**: Design solution considering the tests written
2. **Review Agent**: Validate it handles the task and edge cases
3. Loop if needed
4. [COMPACT: task, worktree, solution design, step]

#### Phase 2B.3: Development Plan

**Agent Pattern**: Plan → Review → Loop (max 3-5 iterations)

1. **Planning Agent**: Plan changes based on design
2. **Review Agent**: Validate plan against design
3. Loop if needed
4. [COMPACT: task, worktree, solution plan, step]

#### Phase 2B.4: Implementation (GREEN Phase)

1. **Implementation Agent**: Write solution and make unit tests pass
2. **Review Agent**: Check code quality, ensure tests pass
3. Loop if needed
4. **GATE**: All unit tests must pass
5. [COMPACT: task, worktree, solution design, step]

#### Phase 2B.5: Integration Tests (RED Phase)

**Agent Pattern**: Design → Review → Write → Review

1. **Design Agent**: Design integration test scenarios
2. **Review Agent**: Validate coverage of component interactions
3. **Write Tests Agent**: Implement failing integration tests
4. **Review Agent**: Validate test quality
5. **GATE**: Integration tests must fail for the right reasons
6. [COMPACT: task, worktree, integration test design, step]

#### Phase 2B.6: Integration Implementation (GREEN Phase)

1. **Implementation Agent**: Fix code to pass integration tests
2. **Review Agent**: Validate fixes, check for regressions
3. Loop if needed
4. **GATE**: All integration tests must pass
5. [COMPACT: task, worktree, development design, step]

#### Phase 2B.7: Refactoring (REFACTOR Phase)

1. **Refactor Agent**: Improve code quality while keeping tests green
2. **Review Agent**: Validate improvements
3. Loop if needed
4. [COMPACT: task, worktree, step]

---

### Phase 3: Design Alignment Check

1. **Review Agent**: Check if code follows original design intent
2. **If misaligned**:
   - **Evaluation Agent**: Determine if design should change or code should refactor
   - If needed, loop back to Phase 2
3. [COMPACT: task, worktree, step]

### Phase 4: Commit Changes

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **Commit Message Agent**: Write commit message following `@conventional-commits`
2. **Review Agent**: Validate format and clarity
3. Loop if needed
4. **Main Agent**: Execute commit:

   ```bash
   git add <relevant-files>
   git commit -m "message"
   ```

5. [COMPACT: task, worktree, step]

### Phase 5: Refactor

> **Note**: If you used Phase 2A (full cycle), this phase is optional
> as refactoring is already included. Only evaluate if additional
> refactoring is needed based on new insights.

1. **Evaluation Agent**: Evaluate code for refactoring needs (OK to have no changes)
2. [COMPACT: task, worktree, evaluation, step]
3. **If refactoring needed**: Restart from Phase 0 (Initial Setup) with refactoring as new task
4. [COMPACT: task, worktree, step]

### Phase 6: Pull Request Management

#### Phase 6.1: PR Creation (If no PR exists yet)

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **PR Message Agent**: Write PR description
2. **Review Agent**: Validate completeness and clarity
3. Loop if needed
4. **Main Agent**: Create PR:

   ```bash
   gh pr create -a @me --title "..." --body "..."
   ```

5. [COMPACT: task, worktree, step]

#### Phase 6.2: Push Changes (If PR already exists)

Simply push the commits to the remote repository

#### Phase 6.3: Review Wait Period

Wait 10 minutes for another agent on GitHub to review the PR

#### Phase 6.4: Acting on Review Comments

1. **Check Comments Agent**: Fetch latest comments on the PR
2. **If no comment** or review failed: Wait for user input
3. **If there are comments**:
   1. **Parse Agent**: Extract and categorize issues
   2. **Categorize Agent**: Create two lists:
      - Issues to address NOW
      - Issues to address LATER (follow-up PR)
   3. **For each LATER issue**:
      - Ask user if GitHub issue should be created
      - If yes: Write → Review → Create issue
      - [COMPACT: task, worktree, issue lists, step]
   4. Mark comment as resolved
   5. **For NOW issues**:
      - Ask user which to address NOW, ignore, or defer
      - [COMPACT: NOW list, worktree, step]
      - Restart from Phase 0 (Initial Setup) with NOW issues as new task
4. **If no more issues**: Merge the PR

### Phase 7: Closing the Task

1. **If GitHub issue exists**: Mark it as complete
2. **Update Agent**: Mark task complete in roadmap/task list if exists
3. Remove worktree:

   ```bash
   git worktree remove ../task-name-worktree
   ```

4. Run `/clear`

## Context Management

### Compact Marker Format

Throughout this document, `[COMPACT: item1, item2, ...]` indicates running `/compact` and remembering the listed items.

Example: `[COMPACT: task, worktree, step]` means:
- Run `/compact`
- Remember: current task, worktree name, step number

### What to Preserve

- Current task description
- Worktree name
- Current phase/step number
- Relevant artifacts (designs, plans, decisions)

## Quality Assurance

1. Tests are written before implementation (TDD approach)
2. Multiple review cycles ensure quality
3. Design-code alignment is validated
4. Refactoring opportunities are systematically evaluated

## Integration

1. This workflow integrates with existing Git and GitHub processes
2. Follows conventional commit and branch naming standards
3. Supports automated issue tracking and project management

## Compliance

**This workflow MUST be followed for all coding tasks** to ensure:

1. Consistent code quality
2. Comprehensive test coverage
3. Proper documentation and design
4. Effective collaboration and review processes
5. Maintainable and robust software solutions
