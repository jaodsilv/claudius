# PR-Create Workflow Output Template

This template defines the structure for output from the PR creation workflow agents.

## Change Analysis Output

```markdown
## Change Analysis

### Overview
- **Branch**: [branch-name]
- **Base**: [base-branch]
- **Commits**: [count]
- **Files Changed**: [count]

### Commit Summary
| Hash | Message | Files |
|------|---------|-------|
| abc1234 | feat: description | 3 |

### Changes by Type
- **Features**: [count]
- **Fixes**: [count]
- **Refactoring**: [count]
- **Documentation**: [count]

### Files Changed
| File | Insertions | Deletions | Change Type |
|------|------------|-----------|-------------|
| src/file.ts | +50 | -10 | Modified |

### Breaking Changes
- [ ] Contains breaking changes
- **Details**: [if applicable]
```

## Description Generator Output

```markdown
## Generated PR Content

### Title
[type]: [concise description]

### Body

## Summary
[2-3 sentence summary of changes]

## Changes
- [Change 1]
- [Change 2]

## Test Plan
- [ ] [Test step 1]
- [ ] [Test step 2]

## Related Issues
- Closes #[issue]
- Related to #[issue]
```

## Review Preparer Output

```markdown
## Review Preparation

### Suggested Reviewers
| Reviewer | Reason |
|----------|--------|
| @username | Owns affected code |

### Review Focus Areas
1. **Area 1**: [path/to/file.ts:L42-L87]
   - Reason to focus here

### Complexity Indicators
- **Risk Level**: [Low | Medium | High]
- **Review Time**: ~[X] minutes

### Self-Review Checklist
- [ ] Code follows project conventions
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No sensitive data exposed
- [ ] Breaking changes documented
```

## Final PR Creation Output

```markdown
## PR Created Successfully

### Details
- **PR Number**: #[number]
- **URL**: [url]
- **Title**: [title]
- **Status**: [Draft | Ready for Review]

### Next Steps
1. Wait for CI checks
2. Request reviews from suggested reviewers
3. Address any feedback with `/gitx:address-review` (for comments) or `/gitx:address-ci` (for failures)
```
