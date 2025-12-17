# Coding Task Workflow Process

> This workflow process **MUST** be followed for all coding tasks.
> It ensures consistent, high-quality development practices using Test-Driven Development (TDD) principles
> and multi-agent collaboration.

## Overview

This workflow is designed to be followed sequentially,
where each upper-level task must wait for the worker to finish before continuing with the next step.
The process leverages multiple specialized agents via the Task tool to ensure thorough testing, design, and implementation.

## Workflow Process

### 0. Initial Setup

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

### 1. Test Requirement Evaluation

Create a new agent for the task using the Task tool to evaluate the need for tests:

1. **If it is a refactoring**: Evaluate if it needs new tests
2. **If it is a cleanup** or something that does not require new tests: Consider it does not need new tests  
3. **If it is a bug fix or a new feature**: New tests are required

### 2. TDD Approach Selection

Based on task complexity, choose the appropriate TDD approach:

#### When to use `/tdd-workflows:tdd-cycle` (Full Cycle)

Use the full cycle for:

1. Standard features with well-defined requirements
2. New modules or components with clear boundaries
3. Bug fixes where test coverage already exists
4. Tasks with straightforward test scenarios

#### When to use individual commands

Use individual commands (`tdd-red`, `tdd-green`, `tdd-refactor`) for:

1. Complex tasks requiring iterative design exploration
2. Experimental or research-oriented development
3. Tasks where you need intervention between phases
4. Integration with existing complex test suites
5. Performance-critical code requiring custom optimization

---

### 2A. Full Cycle Approach (Recommended for most tasks)

Use the tdd-workflows plugin for the complete TDD cycle:

1. Run `/tdd-workflows:tdd-cycle` with the task requirements
   - Handles test specification, design, and architecture
   - Executes complete RED-GREEN-REFACTOR cycle
   - Includes integration tests with failing-first discipline
   - Provides performance testing and final review
   - Uses specialized agents (test-automator, backend-architect, code-reviewer, architect-review)

2. Run `/compact` to compact the context window, remember the task, the worktree name,
   and the step number you are working on

3. Skip to Phase 3: Design Alignment Check

---

### 2B. Individual Commands Approach (For complex tasks)

#### 2B.1 Unit Tests (RED Phase)

Use the tdd-workflows plugin for structured failing test creation:

1. Run `/tdd-workflows:tdd-red` with the task requirements
   - Plugin provides framework-specific patterns (Jest, pytest, Go, RSpec)
   - Enforces test-first discipline with failure verification
   - Covers happy paths, edge cases, and error scenarios

2. **GATE**: Verify all tests fail with meaningful error messages before proceeding

3. Run `/compact` to compact the context window, remember the task, the worktree name,
   and the step number you are working on

#### 2B.2 Solution Design

1. **In a new agent** (using the Task tool to create this agent): Design and document design of the solution. Consider the tests written.
2. **In a new agent** (using the Task tool to create this agent): Review design, especially if it handles the task at hand
   - *Looping between 2B.2.1 and 2B.2.2 if needed, two new agents (Task tool) per loop round*
3. Run `/compact` to compact the context window, remember the task, the worktree name, the solution design,
   and the step number you are working on

#### 2B.3 Development Plan

1. **In a new agent** (using the Task tool to create this agent): Plan changes based on design
2. **In a new agent** (using the Task tool to create this agent): Review plan
   - *Looping between 2B.3.1 and 2B.3.2 if needed, two new agents (Task tool) per loop round*
3. Run `/compact` to compact the context window, remember the task, the worktree name, the solution plan,
   the development design, and the step number you are working on

#### 2B.4 Implementation (GREEN Phase)

1. Run `/tdd-workflows:tdd-green` to implement minimal code that passes unit tests
   - Plugin enforces "minimal code that could possibly work"
   - Uses techniques: Fake It, Obvious Implementation, Triangulation
   - Avoids over-engineering during this phase

2. **GATE**: All unit tests must pass before proceeding

3. Run `/compact` to compact the context window, remember the task, the worktree name, the solution design,
   and the step number you are working on

#### 2B.5 Integration Tests (RED Phase)

1. Run `/tdd-workflows:tdd-red` for integration tests
   - Focus on component interactions and API contracts
   - Tests must fail initially

2. **GATE**: Verify integration tests fail for the right reasons

3. Run `/compact` to compact the context window, remember the task, the worktree name,
   and the step number you are working on

#### 2B.6 Integration Implementation (GREEN Phase)

1. Run `/tdd-workflows:tdd-green` for integration test requirements
   - Focus on component interaction and data flow

2. **GATE**: All integration tests must pass

3. Run `/compact` to compact the context window, remember the task, the worktree name, the development design,
   and the step number you are working on

#### 2B.7 Refactoring (REFACTOR Phase)

1. Run `/tdd-workflows:tdd-refactor` to improve code quality
   - Plugin applies SOLID principles, removes duplication
   - Includes code smell detection and design patterns
   - Ensures tests stay green throughout

2. Run `/compact` to compact the context window, remember the task, the worktree name,
   and the step number you are working on

---

### 3. Design Alignment Check

1. **In a new agent** (using the Task tool to create this agent): Review if code follows original design intent
2. **If it does not follow the design**:
   1. **In a new agent** (using the Task tool to create this agent):
      Review if the design should be changed or the code should be refactored considering the task at hand
   2. If needed, loop back to Phase 2 (re-run tdd-cycle or individual commands as appropriate)
3. Run `/compact` to compact the context window, remember the task, the worktree name,
   and the step number you are working on

### 4. Commit Changes

1. **In a new agent** (using the Task tool to create this agent): Write commit message
2. **In a new agent** (using the Task tool to create this agent): Review commit message
   - *Looping between 4.1 and 4.2 if needed, two new agents (Task tool) per loop round*
3. **In this main agent**: Commit changes using the message written by the agent in 4.1
4. Run `/compact` to compact the context window, remember the task, the worktree name, and the step number you are working on

### 5. Refactor

> **Note**: If you used `/tdd-workflows:tdd-cycle` in Phase 2, this phase is optional
> as refactoring is already included in the cycle. Only evaluate if additional
> refactoring is needed based on new insights.

1. **In a new agent** (using the Task tool to create this agent):
   Evaluate the code for refactoring needs. It is ok to not have anything to change
2. Run `/compact` to compact the context window, remember the task, the worktree name, the evaluation above,
   and the step number you are working on
3. **If the design should be changed**: Restart the process from step 1 with the refactoring as the new task
4. Run `/compact` to compact the context window, remember the task, the worktree name, and the step number you are working on

### 6. Pull Request Management

#### 6.1 PR Creation (If no PR exists yet)

1. **In a new agent** (using the Task tool to create this agent): Write PR message
2. **In a new agent** (using the Task tool to create this agent): Review PR message
   - *Looping between 6.1.1 and 6.1.2 if needed, two new agents (Task tool) per loop round*
3. **In this main agent**: Create PR using the message written by the agent in 6.1.1
4. Run `/compact` to compact the context window, remember the task, the worktree name, and the step number you are working on

#### 6.2 Push Changes (If PR already exists)

Simply push the commits to the remote repository

#### 6.3 Review Wait Period

Wait 10 minutes for another agent on GitHub to review the PR

#### 6.4 Acting on Review Comments

1. **In a new agent** (using the Task tool to create this agent): Check the latest comments on the PR
2. **If there is no comment**, or if the latest Claude comment is that it failed to run:
   Wait for user input and try again after user grants permission
3. **If there are comments**:
   1. **In a new agent** (using the Task tool to create this agent): Parse the latest Claude comment
   2. **If there are issues to address**:
      1. **In a new agent** (using the Task tool to create this agent): Create two check lists:
         1. Issues to address NOW
         2. Issues to address LATER in a follow-up PR
      2. **While the list of Issues to address LATER is not empty**:
         1. Ask user if they want to create a GitHub issue for the FIRST issue in the list of Issues to address LATER, if yes:
            1. **In a new agent** (using the Task tool to create this agent): Write a GitHub issue text for the FIRST issue
            2. **In a new agent** (using the Task tool to create this agent): Review the GitHub issue text
            3. **In this main agent**: Create a GitHub issue for this issue
         2. Remove the issue from the list of Issues to address LATER
         3. Run `/compact` to compact the context window, remember the task, the worktree name,
            the two lists of issues, and the step number you are working on
      3. Mark the latest Claude comment as closed
      4. **If the list of issues to address NOW is not empty**:
         1. Ask user which they want to be addressed NOW, which should be ignored and which should be done later:
            1. Replace the old list of issues to address NOW with the new list of issues to address NOW
            2. If the new list of issues to address LATER is not empty go back to step 6.4.3.2.2
            3. Ignore the list of ignored issues
         2. Run `/compact` to compact the context window, remember the list of issues to address NOW,
            the worktree name, and the step number you are working on
         3. Restart the process from step 1 with the list of issues to address NOW as the new task
   3. **If there are no more issues to address**:
      1. Merge the PR

### 7. Closing the Task

1. **If there is a GitHub issue**: Mark it as complete
2. **In a new agent** (using the Task tool to create this agent):
   Mark the task as complete if there is a roadmap document, task list, or similar for it
3. Exclude worktree from the git worktree list
4. Run `/clear` to clear the context window

## Important Notes

### Context Management

- Use `/compact` regularly to manage context window size
- Always remember the current task, worktree name, and step number
- Preserve important design decisions and test plans across agent switches

### Agent Usage

- Each design, review, and implementation step should use a dedicated agent via the Task tool
- Allow for iterative loops between design and review phases
- Maintain clear handoffs between agents with sufficient context

### Quality Assurance

- Tests are written before implementation (TDD approach)
- Multiple review cycles ensure quality
- Design-code alignment is validated
- Refactoring opportunities are systematically evaluated

### Integration

- This workflow integrates with existing Git and GitHub processes
- Follows conventional commit and branch naming standards
- Supports automated issue tracking and project management

## Compliance

**This workflow MUST be followed for all coding tasks** to ensure:

1. Consistent code quality
2. Comprehensive test coverage
3. Proper documentation and design
4. Effective collaboration and review processes
5. Maintainable and robust software solutions
