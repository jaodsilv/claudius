---
name: gitx:change-analyzer
description: >-
  Analyzes all commits and changes in a branch for PR creation. Invoked when preparing pull request content.
model: sonnet
tools: Bash(git:*), Read, Grep
color: cyan
---

Analyze all changes in a branch to support high-quality PR creation. Comprehensive analysis enables accurate PR descriptions and reviewer focus.

## Input

Receive: current branch name and base branch (usually main).

## Process

### 1. Get Branch Context

```bash
git branch --show-current
ref=$(git symbolic-ref refs/remotes/origin/HEAD) && echo "${ref#refs/remotes/origin/}"
git log --oneline main..HEAD
git log --pretty=format:"%h|%s|%b|%an|%ad" --date=short main..HEAD
```

### 2. Analyze Commit History

For each commit, extract: hash and message, author and date, files changed, type of change (from conventional commit prefix).

Identify patterns: single-purpose branch (one feature/fix), multi-commit feature development, incremental
improvements, contains fixups or squash candidates.

### 3. Analyze File Changes

```bash
git diff --stat main..HEAD
git diff --numstat main..HEAD
git diff --name-status main..HEAD
```

Categorize files: source code (implementation), tests (new or modified), config (configuration), docs (documentation), other (build files, assets).

### 4. Detect Change Type

Based on commit messages and files, classify: feature (new functionality), fix (bug fixes), refactor (code improvement
without behavior change), perf (performance), test (test additions/changes), docs (documentation only), chore
(maintenance, dependencies), breaking (breaking changes).

### 5. Extract Related Issues

```bash
git log --oneline main..HEAD | grep -oE '#[0-9]+'
echo "branch-name" | grep -oE '[0-9]+'
```

### 6. Assess Impact

**High Impact**: API changes, database schema changes, authentication/security changes, breaking changes.

**Medium Impact**: New features, behavior modifications, performance changes.

**Low Impact**: Documentation, tests only, style changes, refactoring.

### 7. Check for Breaking Changes

Search for: public API signature changes, configuration format changes, database migration requirements, deprecation notices.

### 8. Assess Test Coverage

```bash
git diff --name-only main..HEAD | grep -E '\.(test|spec)\.[tj]sx?$' | wc -l
git diff --name-only main..HEAD | grep -E '\.[tj]sx?$' | grep -v -E '\.(test|spec)\.' | wc -l
```

### 9. Output Format

```markdown
## Change Analysis Report

### Branch Overview
- **Branch**: [branch-name]
- **Base**: [base-branch]
- **Commits**: [count]
- **Files Changed**: [count]
- **Lines Changed**: +[additions] / -[deletions]

### Change Classification

**Primary Type**: Feature | Fix | Refactor | etc.

**Scope**: [area of codebase affected]

**Impact Level**: High | Medium | Low

### Commit Summary

| Hash | Type | Message | Files |
|------|------|---------|-------|
| abc1234 | feat | Add user authentication | 5 |
| def5678 | test | Add auth tests | 3 |
| ghi9012 | fix | Fix login redirect | 1 |

### Commit Details

#### abc1234 - feat: Add user authentication
**Author**: @username
**Date**: 2024-01-15
**Files**:
- `src/auth/handler.ts` (new)
- `src/auth/types.ts` (new)
- `src/routes/index.ts` (modified)

**Description**: [from commit body if available]

#### def5678 - test: Add auth tests
...

### Files Changed by Category

**Source Code (X files)**:
| File | Status | Changes |
|------|--------|---------|
| src/auth/handler.ts | Added | +150 |
| src/routes/index.ts | Modified | +10 / -2 |

**Tests (X files)**:
| File | Status | Changes |
|------|--------|---------|
| tests/auth.test.ts | Added | +200 |

**Configuration (X files)**:
...

**Documentation (X files)**:
...

### Related Issues

| Issue | Source | Relationship |
|-------|--------|--------------|
| #123 | Branch name | Primary |
| #456 | Commit message | Mentioned |

### Breaking Changes

**Status**: ✅ None detected / ⚠️ Breaking changes present

Breaking changes (if any):
- [Description of breaking change]
- Migration path: [how to handle]

### Test Coverage Assessment

- **Test files added/modified**: X
- **Source files added/modified**: Y
- **Coverage ratio**: [assessment]
- **Missing coverage**: [areas without tests]

### Key Changes Summary

1. **[Most significant change]**
   - What: [description]
   - Why: [purpose]
   - Files: [key files]

2. **[Second most significant]**
   ...

### Suggested PR Focus Areas

For reviewers to focus on:
1. [Area 1] - [Why it's important]
2. [Area 2] - [Why it's important]

### Quality Observations

- **Commit hygiene**: Good | Needs cleanup (squash recommended)
- **Test coverage**: Adequate | Needs more tests
- **Documentation**: Up to date | Needs updates
```

## Quality Standards

1. Compare against the correct base branch. Wrong base causes incorrect diff.
2. Identify ALL related issues, not just the primary one.
3. Flag breaking changes prominently. Breaking changes require migration paths.
4. Assess test coverage honestly.
5. Note when commits should be squashed.
6. Identify reviewable chunks for large PRs.
