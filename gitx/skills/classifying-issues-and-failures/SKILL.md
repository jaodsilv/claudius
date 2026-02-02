---

name: gitx:classifying-issues-and-failures
description: >-
  Provides classification frameworks for issues, CI failures, and review comments.
  Use when categorizing items by type, effort, or priority in analysis agents.
version: 1.0.0
allowed-tools: []
model: haiku
---

# Classifying Issues and Failures

Standard classification frameworks for consistent categorization.

## Issue Types

| Type        | Description                                |
| ----------- | ------------------------------------------ |
| bug         | Defects, incorrect behavior                |
| feature     | New functionality                          |
| enhancement | Improvements to existing features          |
| refactor    | Code restructuring without behavior change |
| docs        | Documentation updates                      |
| chore       | Maintenance, dependencies, tooling         |

## CI Failure Types

| Type          | Description                    | Priority    |
| ------------- | ------------------------------ | ----------- |
| build-failure | Compilation/bundling errors    | 1 (highest) |
| type-error    | TypeScript/Flow type checking  | 2           |
| test-failure  | Unit/integration/e2e tests     | 3           |
| lint-error    | ESLint, Prettier, formatters   | 4           |
| security-scan | Vulnerability detections       | 5           |
| coverage-drop | Test coverage below threshold  | 6           |

## Review Comment Types

| Type          | Description                     |
| ------------- | ------------------------------- |
| code-style    | Formatting, naming, conventions |
| logic-error   | Bugs, incorrect behavior        |
| performance   | Efficiency concerns             |
| security      | Vulnerabilities, auth issues    |
| documentation | Missing docs, unclear code      |
| testing       | Coverage, test quality          |
| architecture  | Design concerns, patterns       |

## Effort Levels

| Level       | Time Estimate | Scope                 |
| ----------- | ------------- | --------------------- |
| trivial     | < 5 min       | Single line change    |
| minor       | 5-15 min      | Localized changes     |
| moderate    | 15-60 min     | Multiple files        |
| significant | > 1 hour      | Architectural changes |

## Priority Ordering

### CI Failures

Order by dependency: build > types > tests > lint > coverage

### Review Comments

Order by impact:

1. Logic errors and security (blocking)
2. Dependency order (address dependencies first)
3. Effort level (trivial first for quick wins)
4. Code style and documentation (last)
