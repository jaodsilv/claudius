---
name: gitx:categorizing-review-concerns
description: >-
  Categorizes potential review concerns by priority and type. Use when preparing
  PRs for review or when analyzing review feedback patterns.
allowed-tools: []
model: sonnet
---

# Categorizing Review Concerns

Systematically identify and prioritize areas reviewers will question.

## Concern Categories

### Code Quality Patterns

Flag for review:

- Complex logic without comments
- Long functions/files (>200 lines)
- Duplicate code blocks
- Hard-coded values (magic numbers, strings)
- Missing error handling
- Inconsistent naming conventions

### Architecture Patterns

Flag for review:

- New patterns introduced (not matching existing code)
- Deviation from established patterns
- Tight coupling between modules
- Missing abstractions
- Circular dependencies
- Layer violations (e.g., UI calling DB directly)

### Security Patterns

Flag for review:

- Input validation missing or incomplete
- Authentication/authorization gaps
- Sensitive data handling (PII, credentials)
- SQL injection potential (string concatenation)
- XSS vulnerabilities (unescaped output)
- Insecure direct object references

### Performance Patterns

Flag for review:

- N+1 query patterns
- Missing database indexes
- Large payloads without pagination
- Unnecessary computation in loops
- Memory leak potential (event listeners, closures)
- Synchronous operations that should be async

### Testing Patterns

Flag for review:

- Missing test coverage for new code
- Test quality issues (assertions, mocking)
- Edge cases not covered
- Integration tests missing
- Flaky test indicators

## Priority Classification

### High Priority (Reviewers Will Ask)

Issues that block merge or require immediate attention:

- Security vulnerabilities
- Breaking changes
- Missing critical tests
- Data integrity risks

### Medium Priority (Worth Addressing)

Issues that improve quality but aren't blockers:

- Code clarity improvements
- Performance optimizations
- Additional test coverage
- Documentation gaps

### Low Priority (Nice to Address)

Polish items for consideration:

- Style preferences
- Minor refactoring opportunities
- Optional enhancements
