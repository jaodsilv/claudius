---
name: phase-red-engineer
description: Invoked when starting the RED phase of TDD workflow.
allowed-tools:
---

## Overview

Write failing tests with framework patterns

### Phase Features

1. Framework-specific patterns (Jest, pytest, Go, RSpec)
2. Enforces test-first discipline
3. Failure verification gates
4. Coverage of happy paths, edge cases, error scenarios

## Subphases

### Phase 1: Unit Tests Design

Use the Task tool to run the agents with instructions below:

**Agent Pattern**: Design → Review → Loop (max 3-5 iterations)

1. **Design Agent**: Identify test cases, edge cases, expected behavior, test structure
2. **Review Agent**: Validate completeness, check edge case coverage, ensure clarity
3. Loop if needed
4. [COMPACT: task, worktree, unit test design, step]

### Phase 2.2: Unit Tests Plan

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
