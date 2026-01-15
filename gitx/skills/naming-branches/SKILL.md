---

name: gitx:naming-branches
description: >-
  Applies project-specific branch naming conventions for this repository.
  Invoked when creating branches, worktrees, or validating branch names.
  Use when needing project-specific patterns or workflow integration rules
---

# Naming Branches

This skill provides project-specific branch naming rules.
Claude already knows standard conventions (feature/, bugfix/, hotfix/, release/).

## Branch Type Selection

### From Issue Labels

Map GitHub issue labels to branch types:

| Label | Branch Type |
|-------|-------------|
| bug | bugfix/ |
| feature, enhancement | feature/ |
| documentation | docs/ |
| refactor | refactor/ |
| hotfix, critical | hotfix/ |
| (no label) | feature/ |

### From Issue Title

If no labels, infer from keywords:

- "fix", "bug", "error", "crash" -> bugfix/
- "add", "implement", "new" -> feature/
- "update docs", "readme" -> docs/
- Otherwise -> feature/

## Branch Name Format

```text
<type>/issue-<number>-<slug>
```

**Slug Rules**:
1. Lowercase only
2. Hyphens to separate words
3. Remove special characters
4. Maximum 30 characters for slug portion
5. No consecutive hyphens

**Examples**:

```text
feature/issue-123-add-dark-mode
bugfix/issue-456-fix-login-error
docs/issue-789-update-readme
```

## For Task Descriptions

When no issue number:

```text
<type>/<slugified-description>
```

**Example**: "add user authentication" -> `feature/add-user-authentication`

## Validation Checklist

Before creating a branch, verify:

- [ ] Type prefix matches change nature
- [ ] Uses lowercase letters, numbers, hyphens only
- [ ] No consecutive, leading, or trailing hyphens
- [ ] Issue number included (if applicable)
- [ ] Total length under 50 characters

## Integration with Conventional Commits

Branch names guide commit scopes:

```text
# Branch: feature/issue-123-user-auth
# Commits:
feat(auth): implement OAuth2 login
test(auth): add authentication tests
```
