---
name: dotclaude:tdd-workflow
description: >-
  Provides a comprehensive test-driven development workflow with red-green-refactor
  cycle, test isolation, and continuous integration practices.
---

# TDD Workflow

## When to Use This Skill

This skill should be invoked when:

1. Starting a new coding task
2. Working on feature development
3. Fixing bugs that require new tests
4. Planning development approach
5. Reviewing code quality and completeness

## Overview

This workflow ensures consistent, high-quality development using Test-Driven Development (TDD) principles with multi-agent
collaboration. It follows a sequential process where each phase builds upon the previous, with iterative design-review cycles
throughout.

## Core Principles

1. **Tests First** - Write tests before implementation (TDD)
2. **Multi-Agent Collaboration** - Each phase uses specialized agents
3. **Design Before Code** - Plan thoroughly before implementation
4. **Iterative Review** - Design and review cycles at each step (max 3-5 iterations)
5. **Context Management** - Regular compaction to manage memory
6. **Quality Gates** - Multiple validation checkpoints

## Quick Reference

### Workflow Phases

| Phase | Name               | Key Action                      |
|-------|--------------------|---------------------------------|
| 0     | Setup              | Create git worktree             |
| 1     | Evaluation         | Determine if tests needed       |
| 2     | Testing            | Design, plan, write tests       |
| 3     | Solution           | Design, plan, implement, fix    |
| 4     | Commit             | Create conventional commit      |
| 5     | Refactor           | Evaluate improvements           |
| 6     | PR                 | Create/update, handle reviews   |
| 7     | Close              | Complete and cleanup            |

### Standard Agent Pattern

Every major step follows this pattern:

```text
1. Design/Plan/Write Agent
2. Review Agent
3. Loop if needed (max 3-5 iterations)
4. [COMPACT: relevant context]
5. Proceed
```

## Detailed Workflow

### Phase 0: Initial Setup

**Purpose:** Isolate work in dedicated git worktree

```bash
git worktree add -b <branch-type>/<task-name> ../task-name-worktree
cd ../task-name-worktree
```

**Remember**: Worktree name for entire workflow. Follow `dotclaude:conventional-branch` skill.

### Phase 1: Test Requirement Evaluation

**Purpose:** Determine testing strategy

| Task Type       | Tests Required        |
|-----------------|-----------------------|
| New feature     | Yes                   |
| Bug fix         | Yes                   |
| Refactoring     | Evaluate case-by-case |
| Cleanup/chores  | Usually no            |

**Decision:** Skip to Phase 3 if no tests needed.

### Phase 2: Testing Phase

Only if tests are required from Phase 1. Use `dotclaude:tdd-approach-selection` skill to choose between
full cycle or individual phases approach.

#### Phase 2.1: Unit Tests Design

**Agent Pattern**: Design → Review → Loop (max 3-5 iterations)

1. **Design Agent**: Identify test cases, edge cases, expected behavior, test structure
2. **Review Agent**: Validate completeness, check edge case coverage, ensure clarity
3. Loop if needed
4. [COMPACT: task, worktree, unit test design, step]

#### Phase 2.2: Unit Tests Plan

**Agent Pattern**: Plan → Review → Loop (max 3-5 iterations)

1. **Plan Agent**: Create test implementation plan, define file structure, list test functions, specify assertions
2. **Review Agent**: Validate against design, check practical feasibility, ensure coverage
3. Loop if needed
4. [COMPACT: task, worktree, unit test plan, design, step]

#### Phase 2.3: Unit Tests Writing

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **Write Agent**: Implement unit tests (**tests should fail** - no implementation yet)
2. **Review Agent**: Check test quality, validate logic, ensure tests will catch issues
3. Loop if needed
4. [COMPACT: task, worktree, step]

#### Phase 2.4: Integration Tests Design

**Agent Pattern**: Design → Review → Loop (max 3-5 iterations)

1. **Design Agent**: Identify integration points, define scenarios, consider system interactions
2. **Review Agent**: Validate coverage, check realistic scenarios, ensure proper scope
3. Loop if needed
4. [COMPACT: task, worktree, integration test design, step]

#### Phase 2.5: Integration Tests Plan

**Agent Pattern**: Plan → Review → Loop (max 3-5 iterations)

1. **Plan Agent**: Create implementation plan, define setup/teardown, specify mocks and test data
2. **Review Agent**: Validate against design, check feasibility, ensure adequate coverage
3. Loop if needed
4. [COMPACT: task, worktree, integration test plan, design, step]

#### Phase 2.6: Integration Tests Writing

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **Write Agent**: Implement integration tests (**tests should fail** - no implementation yet)
2. **Review Agent**: Check quality, validate integration points, ensure realistic scenarios
3. Loop if needed
4. [COMPACT: task, worktree, step]

### Phase 3: Solution Phase

#### Phase 3.1: Solution Design

**Agent Pattern**: Design → Review → Loop (max 3-5 iterations)

1. **Design Agent**: Design solution architecture, **consider tests from Phase 2**, plan code structure
2. **Review Agent**: Validate it solves the problem, check it passes tests, ensure maintainability
3. Loop if needed
4. [COMPACT: task, worktree, solution design, step]

#### Phase 3.2: Development Plan

**Agent Pattern**: Plan → Review → Loop (max 3-5 iterations)

1. **Plan Agent**: Create implementation steps, list files to modify/create, define order
2. **Review Agent**: Validate against design, check completeness, ensure logical order
3. Loop if needed
4. [COMPACT: task, worktree, solution plan, design, step]

#### Phase 3.3: Solution Writing

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **Write Agent**: Implement solution, **make unit tests pass**, follow design and plan
2. **Review Agent**: Check code quality, validate against design, **ensure unit tests pass**
3. Loop if needed
4. [COMPACT: task, worktree, solution design, step]

#### Phase 3.4: Fix Code for Integration Tests

**Agent Pattern**: Fix → Review → Loop (max 3-5 iterations)

1. **Fix Agent**: **Make integration tests pass**, adjust code as needed
2. **Review Agent**: Validate fixes, **ensure integration tests pass**, check for regressions
3. Loop if needed
4. [COMPACT: task, worktree, development design, step]

#### Phase 3.5: Design Alignment Check

1. **Validate Agent**: Compare code to design, identify deviations, assess if justified
2. **If Misaligned**:
   - **Decision Agent**: Should design change? Should code refactor? What's better for the task?
   - If design needs change: Return to Phase 3.1
   - If code needs refactor: Return to Phase 3.3
   - If aligned: Proceed
3. [COMPACT: task, worktree, step]

### Phase 4: Commit Changes

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **Write Agent**: Create commit message following `dotclaude:conventional-commits` skill
2. **Review Agent**: Validate format, check clarity, ensure accuracy
3. Loop if needed
4. **Main Agent**: Execute commit:

```bash
git add <relevant-files>
git commit -m "message"
```

1. [COMPACT: task, worktree, step]

### Phase 5: Refactor

> **Note**: This phase is optional if using full cycle approach from Phase 2.
> Only evaluate if additional refactoring is needed based on new insights.

1. **Evaluate Agent**: Review code quality, identify improvements (**OK to have no changes**)
2. [COMPACT: task, worktree, evaluation, step]
3. **If refactoring needed**: Restart from Phase 0 with refactoring as new task
4. **If no refactoring**: Proceed to Phase 6
5. [COMPACT: task, worktree, step]

### Phase 6: Pull Request Management

#### Phase 6.1: PR Creation (If no PR exists)

**Agent Pattern**: Write → Review → Loop (max 3-5 iterations)

1. **Write Agent**: Summarize changes, explain motivation, list testing done, reference issues
2. **Review Agent**: Validate completeness, check clarity, ensure proper format
3. Loop if needed
4. **Main Agent**: Create PR:

```bash
gh pr create -a @me --title "..." --body "..."
```

1. [COMPACT: task, worktree, step]

#### Phase 6.2: Push Changes (If PR exists)

```bash
git push
```

#### Phase 6.3: Review Wait Period

Wait 10 minutes for automated review.

#### Phase 6.4: Acting on Review Comments

1. **Check Agent**: Fetch latest PR comments, identify if review is ready
2. **If no comment or failed**: Wait for user input
3. **If there are comments**:
   1. **Parse Agent**: Extract issues, categorize by severity
   2. **Categorize Agent**: Create two lists: NOW vs LATER
   3. **For each LATER issue**:
      - Ask user if GitHub issue should be created
      - If yes: Write → Review → Create issue
      - [COMPACT: task, worktree, lists, step]
   4. Mark comment as resolved
   5. **For NOW issues**:
      - Ask user which to address NOW, ignore, or move to LATER
      - [COMPACT: NOW list, worktree, step]
      - Restart from Phase 0 with NOW issues as new task
4. **If no issues remain**: Merge the PR

### Phase 7: Closing the Task

1. **If GitHub issue exists**: Close it
2. **Update Agent**: Mark task complete in roadmap/task list if exists
3. Remove worktree:

```bash
git worktree remove ../task-name-worktree
```

1. Run `/clear`

## Quality Gates

### Testing Gates

- [ ] Unit tests designed and reviewed
- [ ] Unit tests written and reviewed
- [ ] Integration tests designed and reviewed
- [ ] Integration tests written and reviewed
- [ ] All tests passing

### Implementation Gates

- [ ] Solution designed and reviewed
- [ ] Development plan created and reviewed
- [ ] Code written and reviewed
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Code aligns with design

### Commit Gates

- [ ] Commit message follows conventional commits
- [ ] Only relevant files included
- [ ] Changes are cohesive
- [ ] Tests included with code changes

### PR Gates

- [ ] PR description is comprehensive
- [ ] All tests passing
- [ ] Code review completed
- [ ] Review comments addressed
- [ ] No remaining blockers

## Best Practices

### DO

1. Follow phases sequentially
2. Use dedicated agents for each step
3. Compact context regularly
4. Write tests before implementation
5. Loop design-review when needed (max 3-5 iterations)
6. Keep worktree name throughout workflow
7. Document decisions in design phases
8. Handle review feedback systematically

### DON'T

1. Skip testing phases for features/fixes
2. Write code before tests (except refactoring)
3. Merge design and implementation in same agent
4. Forget to compact context
5. Skip review cycles
6. Leave worktrees around
7. Mix unrelated changes
8. Ignore review comments

## Integration with Other Skills

| Skill                             | Phase | Purpose           |
|-----------------------------------|-------|-------------------|
| `dotclaude:tdd-approach-selection`| 2     | Choose approach   |
| `dotclaude:conventional-commits`  | 4     | Commit messages   |
| `dotclaude:conventional-branch`   | 0     | Branch naming     |
| `dotclaude:code-quality`          | 2-3   | Review checkpoints|

## Related Commands

1. `/coding-task:start` - Start a coding task with TDD orchestration

## When to Deviate

This workflow is comprehensive and may be overkill for:

1. **Trivial changes**: Typo fixes, simple documentation
2. **Emergency hotfixes**: Critical production issues (but still test!)
3. **Experiments**: Spike/POC work (document as such)

**Deviation requires explicit justification.**

## Troubleshooting

### Too many agents/context issues

1. Compact more frequently
2. Combine similar review steps
3. Use shorter agent prompts

### Tests are too complex

1. Break into smaller units
2. Reconsider design
3. May need simpler approach

### Design-code misalignment

1. Phase 3.5 exists for this
2. Either update design or refactor code
3. Don't skip this validation

### Review feedback overwhelming

1. Categorize NOW vs LATER
2. Create follow-up issues
3. Address incrementally

## Success Criteria

Workflow is successful when:

1. All tests pass
2. Code follows design
3. Commits are clean and conventional
4. PR is approved and merged
5. No technical debt introduced
6. Task is documented and closed
7. Worktree is cleaned up

## Reference

This skill embodies TDD principles with systematic quality assurance through multi-agent collaboration. It ensures maintainable,
well-tested code with clear documentation of decisions and tradeoffs.

For canonical workflow documentation, see: `@dotclaude/shared/coding-task-workflow.md`
