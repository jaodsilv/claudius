---
name: gitx:naming-worktrees
description: >-
  Generates abbreviated worktree directory names from branch names.
  Invoked when creating worktrees to offer short, meaningful options.
allowed-tools: AskUserQuestion, Bash(git worktree list), Bash(gh repo view:*), Bash(rg:*), Bash(awk:*), Skill(gitx:validating-directory-names)
model: haiku
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

### 5. Calculating Worktree Paths

1. Get repository root path: !`git worktree list | rg "\[$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')$\]" | awk -F' ' '{print $1}'`
2. Get parent directory: `dirname` of root, e.g., if root path is `/code/myproject/main`, parent directory is `/code/myproject`
3. Map each option to worktree path: `<parent>/<option>`

### 6. Validate Directory Names

1. For each generated path, use the Skill tool with the skill `gitx:validating-directory-names` to validate directory names.
2. If collision, add numeric suffix: `auth-2`, `auth-3`, ... and try validating again
   - Maximum 10 suffix attempts (`auth`, `auth-2`, ..., `auth-10`)
   - If all 10 collide: "Error: Too many directories with similar names. Please choose a unique custom name."

### 7. Directory Name Selection

1. Present options to user via AskUserQuestion tool

   ```text
   AskUserQuestion:
   Question: "Select worktree directory name for branch `<branch-name>`:"
   Options: [Final generated options from previous steps]
   ```

2. Each option shows the abbreviated name
3. Filter out branch-type words when standalone: `feature`, `bugfix`, `hotfix`, `release`, `chore`, `refactor`, `docs`
4. Final path: `<parent>/<selected-directory-name>`

#### Validating Custom Directory Names

If user types a different alternative:

1. Use Skill tool with gitx:validating-directory-names to validate custom names.
2. On validation failure, the skill returns an error message with a suggested fix.
3. Confirm the full path with user using AskUserQuestion tool

## Examples

For repository root: `/code/myproject/main`

| Input | Options to Ask User | Paths |
| ----- | ------------------- | ----- |
| `feature/issue-123-add-user-auth` | `['auth', 'user-auth', 'add-user-auth']` | `['/code/myproject/auth', '/code/myproject/user-auth', '/code/myproject/add-user-auth']` |
| `bugfix/fix-login-error` | `['error', 'login-error', 'fix-login-error']` | `['/code/myproject/error', '/code/myproject/login-error', '/code/myproject/fix-login-error']` |
| `hotfix/JIRA-789-security-patch` | `['patch', 'security-patch']` | `['/code/myproject/patch', '/code/myproject/security-patch']` |
| `release/v1.2.0` | `['v1.2.0']` | `['/code/myproject/v1.2.0']` |
| `feature/auth` | `['auth']` | `['/code/myproject/auth']` |

## Validation Rules

Generated names must be:

- Lowercase only
- Hyphens for word separation
- No consecutive/leading/trailing hyphens
- Filesystem safe
- Not reserved (`main`, `master`, `develop`, `HEAD`)

## Integration

Used by `/gitx:worktree` and `/gitx:fix-issue` when creating worktrees.
