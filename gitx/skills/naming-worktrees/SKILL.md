---

name: gitx:naming-worktrees
description: >-
  Generates abbreviated worktree directory names from branch names.
  Invoked when creating worktrees to offer short, meaningful options
---

# Naming Worktrees

Generate abbreviated directory names from conventional branch names.

## Input/Output

```text
feature/issue-123-add-user-auth → ['auth', 'user-auth', 'add-user-auth']
bugfix/fix-login-error → ['error', 'login-error', 'fix-login-error']
release/v1.2.0 → ['v1.2.0']
```

## Algorithm

### 1. Parse Branch

Extract description after type prefix: `feature/issue-123-add-auth` → `issue-123-add-auth`

### 2. Remove Issue Patterns

Strip common issue references from start:

| Pattern | Example |
|---------|---------|
| `^issue-\d+-` | `issue-123-` |
| `^#\d+-` | `#123-` |
| `^\d+-` | `123-` |
| `^JIRA-\d+-`, `^BUG-\d+-`, etc. | `JIRA-456-` |

If result empty after removal, keep original (fallback).

### 3. Generate Options

Split by hyphens, then build options from last word to full phrase:

```text
['add', 'user', 'auth'] →
  - auth
  - user-auth
  - add-user-auth
```

### 4. Filter and Limit

1. Remove single-character and numeric-only options
2. Filter meaningless words if only option: `fix`, `add`, `feature`, etc.
3. Keep version strings as-is: `v1.2.0`
4. Limit to 5 options maximum (shortest first)

## Examples

| Input | Output |
|-------|--------|
| `feature/issue-123-add-user-auth` | `['auth', 'user-auth', 'add-user-auth']` |
| `bugfix/fix-login-error` | `['error', 'login-error', 'fix-login-error']` |
| `hotfix/JIRA-789-security-patch` | `['patch', 'security-patch']` |
| `release/v1.2.0` | `['v1.2.0']` |
| `feature/auth` | `['auth']` |
| `feature/issue-123` | `['issue-123']` (fallback) |

## Validation Rules

Generated names must be:
- Lowercase only
- Hyphens for word separation
- No consecutive/leading/trailing hyphens
- Filesystem safe
- Not reserved (`main`, `master`, `develop`, `HEAD`)

## Integration

Used by `/gitx:worktree` and `/gitx:fix-issue` when creating worktrees.
