# TDD Workflow

## When to Use This Skill

This skill is automatically invoked when:

1. Starting a new coding task
2. Working on feature development
3. Fixing bugs that require new tests
4. Planning development approach
5. Reviewing code quality and completeness

## Overview

This workflow ensures consistent, high-quality development using Test-Driven Development (TDD) principles with multi-agent collaboration. It follows a sequential process where each phase builds upon the previous, with iterative design-review cycles throughout.

## Core Principles

1. **Tests First** - Write tests before implementation (TDD)
2. **Multi-Agent Collaboration** - Each phase uses specialized agents
3. **Design Before Code** - Plan thoroughly before implementation
4. **Iterative Review** - Design and review cycles at each step
5. **Context Management** - Regular compaction to manage memory
6. **Quality Gates** - Multiple validation checkpoints

## Quick Reference

### Workflow Phases

1. **0. Setup** → Create git worktree
2. **1. Evaluation** → Determine if tests are needed
3. **2. Testing** → Design, plan, write unit & integration tests
4. **3. Solution** → Design, plan, implement, fix
5. **4. Commit** → Create conventional commit message
6. **5. Refactor** → Evaluate improvement opportunities
7. **6. PR** → Create/update pull request, handle reviews
8. **7. Close** → Complete task and cleanup

### Key Pattern: Design → Review → Loop

Every major step follows:
1. Agent designs/implements
2. Agent reviews
3. Loop if needed (max iterations: reasonable judgment)
4. Compact context

## Detailed Workflow

### Phase 0: Initial Setup

**Purpose:** Isolate work in dedicated git worktree

#### Steps

```bash
git worktree add -b <branch-type>/<task-name> ../task-name-worktree
cd ../task-name-worktree
```

#### Remember

Worktree name for entire workflow

#### Branch naming

Follow `conventional-branch` skill

### Phase 1: Test Requirement Evaluation

#### Purpose

Determine testing strategy

#### Launch agent to evaluate

- **Refactoring:** May or may not need new tests
- **Cleanup/chores:** Usually no new tests
- **Bug fix/new feature:** Requires new tests

#### Decision

Skip to Phase 3 if no tests needed

### Phase 2: Testing Phase

Only if tests are required from Phase 1.

#### 2.1 Unit Tests Design

#### Agent 1: Unit Test Design

- Identify what needs unit testing
- Define test cases and edge cases
- Document expected behavior
- Consider test structure

#### Agent 2: Review Unit Test Design

- Validate completeness
- Check edge case coverage
- Ensure clarity
- Suggest improvements

#### Unit Test Design Loop

If design needs refinement

#### Compact After Unit Test Design

Save task, worktree, unit test design, step number

#### 2.2 Unit Tests Plan

#### Agent 1: Unit Test Plan

- Create specific test implementation plan
- Define test file structure
- List test functions/classes
- Specify assertions and fixtures

#### Agent 2: Review Unit Test Plan

- Validate against design
- Check practical feasibility
- Ensure coverage

#### Unit Test Plan Loop

If plan needs adjustment

#### Compact After Unit Test Plan

Save task, worktree, unit test plan, design, step number

#### 2.3 Unit Tests Writing

#### Agent 1: Write Unit Tests

- Implement unit tests
- **Tests should fail** (no implementation yet)
- Follow testing framework conventions
- Include descriptive test names

#### Agent 2: Review Unit Tests

- Check test quality
- Validate test logic
- Ensure tests will catch issues
- OK if tests are failing

#### Unit Tests Writing Loop

If tests need improvement

#### Compact After Unit Tests Writing

Save task, worktree, step number

#### 2.4 Integration Tests Design

#### Agent 1: Integration Test Design

- Identify integration points
- Define integration test scenarios
- Consider system interactions
- Document integration behavior

#### Agent 2: Review Integration Test Design

- Validate coverage
- Check realistic scenarios
- Ensure proper scope

#### Integration Test Design Loop

If design needs refinement

#### Compact After Integration Test Design

Save task, worktree, integration test design, step number

#### 2.5 Integration Tests Plan

#### Agent 1: Integration Test Plan

- Create implementation plan
- Define test setup/teardown
- Specify mocks and fixtures
- Plan test data

#### Agent 2: Review Integration Test Plan

- Validate against design
- Check feasibility
- Ensure adequate coverage

#### Integration Test Plan Loop

If plan needs adjustment

#### Compact After Integration Test Plan

Save task, worktree, integration test plan, design, step number

#### 2.6 Integration Tests Writing

#### Agent 1: Write Integration Tests

- Implement integration tests
- **Tests should fail** (no implementation yet)
- Set up test environment
- Handle async operations

#### Agent 2: Review Integration Tests

- Check test quality
- Validate integration points
- Ensure realistic scenarios
- OK if tests are failing

#### Integration Tests Writing Loop

If tests need improvement

#### Compact After Integration Tests Writing

Save task, worktree, step number

### Phase 3: Solution Phase

#### 3.1 Solution Design

#### Agent 1: Solution Design

- Design solution architecture
- **Consider tests written in Phase 2**
- Plan code structure
- Identify components needed
- Document approach

#### Agent 2: Review Solution Design

- Validate it solves the problem
- Check it passes tests
- Ensure maintainability
- Suggest improvements

#### Solution Design Loop

If design needs refinement

#### Compact After Solution Design

Save task, worktree, solution design, step number

#### 3.2 Development Plan

#### Agent 1: Development Plan

- Create implementation steps
- List files to modify/create
- Plan code changes
- Define order of implementation

#### Agent 2: Review Development Plan

- Validate against design
- Check completeness
- Ensure logical order

#### Development Plan Loop

If plan needs adjustment

#### Compact After Development Plan

Save task, worktree, solution plan, design, step number

#### 3.3 Solution Writing

#### Agent 1: Write Solution

- Implement the solution
- **Make unit tests pass**
- Follow design and plan
- Write clean, maintainable code

#### Agent 2: Review Solution

- Check code quality
- Validate against design
- **Ensure unit tests pass**
- Suggest improvements

#### Solution Writing Loop

If code needs improvement

#### Compact After Solution Writing

Save task, worktree, solution design, step number

#### 3.4 Fix Code for Integration Tests

#### Agent 1: Fix Code

- **Make integration tests pass**
- Adjust code as needed
- Handle integration edge cases

#### Agent 2: Review Code Fixes

- Validate fixes
- **Ensure integration tests pass**
- Check for regressions

#### Code Fixes Loop

If more fixes needed

#### Compact After Code Fixes

Save task, worktree, development design, step number

#### 3.5 Design vs Code Review

#### Agent 1: Validate Alignment

- Compare code to design
- Identify deviations
- Assess if deviations are justified

#### If Misalignment Detected

#### Agent 2: Determine Action

- Should design change?
- Should code refactor?
- What's better for the task?

#### Alignment Decision

- If design needs change: Return to 3.1
- If code needs refactor: Return to 3.3
- If aligned: Proceed

#### Compact After Design vs Code Review

Save task, worktree, step number

### Phase 4: Commit Changes

#### Agent 1: Write Commit Message

- Follow `conventional-commits` skill
- Summarize changes clearly
- Include body if needed
- Reference issues

#### Agent 2: Review Commit Message

- Validate format
- Check clarity
- Ensure accuracy

#### Commit Message Loop

If message needs improvement

#### Main Agent: Execute Commit

```bash
git add <relevant-files>
git commit -m "message"
```

#### Compact After Commit

Save task, worktree, step number

### Phase 5: Refactor

#### Agent: Evaluate Refactoring Needs

- Review code quality
- Identify improvement opportunities
- Assess technical debt
- **OK to have no changes**

#### Compact After Refactor Evaluation

Save task, worktree, evaluation, step number

#### If Refactoring Needed

- Restart from Phase 1 with refactoring as new task

#### If No Refactoring

- Proceed to Phase 6

#### Compact After Refactor Decision

Save task, worktree, step number

### Phase 6: Pull Request Management

#### 6.1 PR Creation (If no PR exists)

#### Agent 1: Write PR Message

- Summarize all changes
- Explain motivation
- List testing done
- Reference issues

#### Agent 2: Review PR Message

- Validate completeness
- Check clarity
- Ensure proper format

#### PR Message Loop

If message needs improvement

#### Main Agent: Create PR

```bash
gh pr create -a @me --title "..." --body "..."
```

#### Compact After PR Creation

Save task, worktree, step number

#### 6.2 Push Changes (If PR exists)

#### Simple Push

```bash
git push
```

#### 6.3 Review Wait Period

#### Wait for Review

10 minutes for automated review

#### 6.4 Acting on Review Comments

#### Agent 1: Check Comments

- Fetch latest PR comments
- Identify if review is ready

#### If No Comment or Failed

Wait for user input

#### If There Are Comments

#### Agent 2: Parse Comments

- Extract issues found
- Categorize by severity
- Understand feedback

#### Agent 3: Categorize Issues

Create two lists:

1. **Issues to address NOW**
2. **Issues to address LATER** (follow-up PR)

#### For Each LATER Issue

1. Ask user if GitHub issue should be created
2. If yes:
   - **Agent 4:** Write issue text
   - **Agent 5:** Review issue text
   - **Main Agent:** Create GitHub issue
3. Remove from LATER list
4. **Compact:** Save task, worktree, lists, step number

#### Mark Comment as Resolved

```bash
gh api --method PATCH /repos/owner/repo/pulls/comments/<id> \
  -f "minimizedReason=RESOLVED" -f 'isMinimized=true'
```

#### For NOW Issues

1. Ask user which to address NOW, ignore, or move to LATER
2. Update lists accordingly
3. **Compact:** Save NOW list, worktree, step number
4. **Restart from Phase 1** with NOW issues as new task

#### If No Issues Remain

Merge the PR

### Phase 7: Closing the Task

1. **If GitHub issue exists:** Close it
2. **Agent:** Update roadmap/task list if exists
3. **Remove worktree:**

   ```bash
   git worktree remove ../task-name-worktree
   ```

4. **Clear context:** Run `/clear`

## Agent Coordination Patterns

### Design-Review Loop

Standard pattern for most phases:

```text
1. Launch Agent (Design/Plan/Write)
2. Launch Agent (Review)
3. If improvements needed: goto 1
4. Compact context
5. Proceed
```

### Context Compaction

#### When to compact

- After each major sub-phase
- Before launching new agents
- When context is growing large

#### What to remember

- Current task description
- Worktree name
- Current phase/step number
- Relevant artifacts (designs, plans, decisions)

### Agent Handoffs

#### Clear handoffs require

- Summary of what was done
- Current artifacts (design docs, test plans)
- What the next agent should do
- Success criteria

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
5. Loop design-review when needed
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

1. **conventional-commits:** Phase 4 commit messages
2. **conventional-branch:** Phase 0 branch naming
3. **code-quality:** Review checkpoints throughout

## When to Deviate

This workflow is comprehensive and may be overkill for:

- **Trivial changes:** Typo fixes, simple documentation
- **Emergency hotfixes:** Critical production issues (but still test!)
- **Experiments:** Spike/POC work (document as such)

### Deviation Rule

Deviation requires explicit justification

## Troubleshooting

### Too many agents/context issues

- Compact more frequently
- Combine similar review steps
- Use shorter agent prompts

### Tests are too complex

- Break into smaller units
- Reconsider design
- May need simpler approach

### Design-code misalignment

- Phase 3.5 exists for this
- Either update design or refactor code
- Don't skip this validation

### Review feedback overwhelming

- Categorize NOW vs LATER
- Create follow-up issues
- Address incrementally

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

This skill embodies TDD principles with systematic quality assurance through multi-agent collaboration. It ensures maintainable, well-tested code with clear documentation of decisions and tradeoffs.

Use this workflow for all substantial coding tasks to maintain consistency and quality across the codebase.
