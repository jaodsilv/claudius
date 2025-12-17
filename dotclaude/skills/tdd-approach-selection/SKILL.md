# TDD Approach Selection

## When to Use This Skill

This skill is automatically invoked when:

1. Starting a coding task that requires tests
2. Deciding between full TDD cycle and individual commands
3. Evaluating task complexity for TDD approach
4. Planning test strategy for a feature or bug fix

## Overview

This skill provides guidance on selecting the appropriate TDD approach using the `tdd-workflows` plugin. It helps you choose
between running the complete TDD cycle (`/tdd-workflows:tdd-cycle`) or using individual commands (`tdd-red`, `tdd-green`,
`tdd-refactor`) based on task characteristics.

## Available TDD Approaches

### Full Cycle Approach

**Command**: `/tdd-workflows:tdd-cycle`

A single command that orchestrates the complete TDD workflow:

1. Test Specification and Design
2. RED Phase - Write failing tests
3. GREEN Phase - Minimal implementation
4. REFACTOR Phase - Code quality improvements
5. Integration and System Tests
6. Continuous Improvement (performance tests, final review)

### Individual Commands Approach

Separate commands for fine-grained control:

| Command | Phase | Purpose |
|---------|-------|---------|
| `/tdd-workflows:tdd-red` | RED | Write failing tests with framework patterns |
| `/tdd-workflows:tdd-green` | GREEN | Minimal implementation to pass tests |
| `/tdd-workflows:tdd-refactor` | REFACTOR | Improve code while keeping tests green |

## Decision Framework

### Use Full Cycle (`/tdd-workflows:tdd-cycle`) When

1. **Standard Features**
   - Well-defined requirements
   - Clear acceptance criteria
   - Straightforward implementation path

2. **New Modules/Components**
   - Clear boundaries
   - Self-contained functionality
   - Minimal dependencies on experimental code

3. **Bug Fixes with Existing Coverage**
   - Test infrastructure already exists
   - Bug can be reproduced with a test
   - Fix is well-understood

4. **Straightforward Test Scenarios**
   - Happy path is clear
   - Edge cases are known
   - No complex mocking required

### Use Individual Commands When

1. **Complex Tasks**
   - Iterative design exploration needed
   - Multiple valid implementation approaches
   - Requirements may evolve during development

2. **Experimental/Research Work**
   - Proof of concept development
   - Technology evaluation
   - Architecture exploration

3. **Need Intervention Between Phases**
   - Custom design review cycles
   - Manual verification checkpoints
   - Integration with external review processes

4. **Complex Test Suites**
   - Existing test infrastructure to integrate with
   - Custom test patterns required
   - Framework-specific considerations

5. **Performance-Critical Code**
   - Custom optimization needed between phases
   - Benchmarking required before refactoring
   - Memory/performance profiling integration

## Quick Decision Matrix

```text
Task Type                    | Recommended Approach
-----------------------------|----------------------
New feature, clear scope     | Full Cycle
Bug fix, simple              | Full Cycle
New module, isolated         | Full Cycle
Refactoring, incremental     | Individual Commands
Complex integration          | Individual Commands
Performance optimization     | Individual Commands
Experimental/POC             | Individual Commands
Legacy code modification     | Individual Commands
```

## Integration with Workflow

### Full Cycle Integration

When using full cycle, the workflow simplifies to:

```text
Phase 0: Initial Setup (git worktree)
Phase 1: Test Requirement Evaluation
Phase 2: /tdd-workflows:tdd-cycle  ← Single command
Phase 3: Design Alignment Check
Phase 4-7: Commit, PR, Close
```

### Individual Commands Integration

When using individual commands:

```text
Phase 0: Initial Setup
Phase 1: Test Requirement Evaluation
Phase 2B.1: /tdd-workflows:tdd-red (unit tests)
Phase 2B.2-3: Solution Design & Development Plan
Phase 2B.4: /tdd-workflows:tdd-green (unit implementation)
Phase 2B.5: /tdd-workflows:tdd-red (integration tests)
Phase 2B.6: /tdd-workflows:tdd-green (integration implementation)
Phase 2B.7: /tdd-workflows:tdd-refactor
Phase 3: Design Alignment Check
Phase 4-7: Commit, PR, Close
```

## Plugin Features by Command

### `/tdd-workflows:tdd-red` Features

1. Framework-specific patterns (Jest, pytest, Go, RSpec)
2. Enforces test-first discipline
3. Failure verification gates
4. Coverage of happy paths, edge cases, error scenarios

### `/tdd-workflows:tdd-green` Features

1. Minimal implementation guidance
2. Techniques: Fake It, Obvious Implementation, Triangulation
3. Anti-over-engineering enforcement
4. Incremental test passing

### `/tdd-workflows:tdd-refactor` Features

1. SOLID principles application
2. Code smell detection
3. Design pattern suggestions
4. Test safety net verification

### `/tdd-workflows:tdd-cycle` Features

All of the above, plus:

1. Requirements analysis
2. Test architecture design
3. Integration test orchestration
4. Performance testing
5. Final code review

## Best Practices

### DO

1. Evaluate task complexity before choosing approach
2. Start with full cycle for standard tasks
3. Switch to individual commands if you need more control
4. Use gates between phases to verify progress
5. Compact context after each major step

### DON'T

1. Use full cycle for highly experimental work
2. Use individual commands for simple, well-defined tasks
3. Skip the approach selection step
4. Mix approaches mid-task without good reason
5. Ignore gate failures

## Reference

For detailed workflow documentation, see:

1. `@dotclaude/shared/coding-task-workflow.md` - Full workflow process
2. `@dotclaude/skills/tdd-workflow/SKILL.md` - TDD principles and phases
