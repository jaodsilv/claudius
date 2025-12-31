---
name: gitx:worktree-name
description: >-
  Generates abbreviated worktree directory name options from branch names.
  Extracts semantic parts, removes issue numbers, and provides short options.
---

# Worktree Name Generator

Generate abbreviated, user-friendly worktree directory names from conventional branch names.

## When to Use This Skill

This skill is automatically invoked when:

1. Creating worktrees and need directory name options
2. Converting branch names to filesystem-safe directory names
3. Offering abbreviated naming choices to users

## Input

A conventional branch name in format `<type>/<description>`:

```text
feature/issue-123-add-user-auth
bugfix/fix-login-error
hotfix/crash-fix
feature/dark-mode
```

## Output

A list of abbreviated directory name options, ordered from shortest to longest:

```text
['auth', 'user-auth', 'add-user-auth']
['error', 'login-error', 'fix-login-error']
['fix', 'crash-fix']
['mode', 'dark-mode']
```

## Abbreviation Algorithm

### Step 1: Parse Branch Name

Extract the description part after the type prefix:

```text
feature/issue-123-add-user-auth → issue-123-add-user-auth
bugfix/fix-login-error → fix-login-error
```

### Step 2: Remove Issue Patterns

Strip common issue reference patterns from the start:

1. `issue-\d+-` → Remove (e.g., `issue-123-`)
2. `#\d+-` → Remove (e.g., `#123-`)
3. `^\d+-` → Remove leading numbers (e.g., `123-`)
4. `JIRA-\d+-`, `BUG-\d+-`, etc. → Remove tracker prefixes

```text
issue-123-add-user-auth → add-user-auth
#456-fix-button → fix-button
789-update-config → update-config
```

### Step 3: Split Into Words

Split the cleaned description by hyphens:

```text
add-user-auth → ['add', 'user', 'auth']
fix-login-error → ['fix', 'login', 'error']
dark-mode → ['dark', 'mode']
```

### Step 4: Generate Options

Create options from shortest to longest by taking words from the end:

1. Last word only
2. Last 2 words
3. Last 3 words
4. ... up to all words

```text
['add', 'user', 'auth'] →
  - auth (1 word)
  - user-auth (2 words)
  - add-user-auth (3 words)
```

### Step 5: Dedupe and Filter

1. Remove duplicates (if description has fewer unique segments)
2. Filter out single-character options
3. Filter out common meaningless words when alone: `fix`, `add`, `update`, `the`, `a`

## Examples

### Example 1: Issue-based Feature

**Input:** `feature/issue-123-add-user-auth`

**Processing:**

1. Parse: `issue-123-add-user-auth`
2. Remove issue: `add-user-auth`
3. Split: `['add', 'user', 'auth']`
4. Generate: `['auth', 'user-auth', 'add-user-auth']`

**Output:** `['auth', 'user-auth', 'add-user-auth']`

### Example 2: Simple Bugfix

**Input:** `bugfix/fix-login-error`

**Processing:**

1. Parse: `fix-login-error`
2. No issue pattern
3. Split: `['fix', 'login', 'error']`
4. Generate: `['error', 'login-error', 'fix-login-error']`

**Output:** `['error', 'login-error', 'fix-login-error']`

### Example 3: Two-word Feature

**Input:** `feature/dark-mode`

**Processing:**

1. Parse: `dark-mode`
2. No issue pattern
3. Split: `['dark', 'mode']`
4. Generate: `['mode', 'dark-mode']`
5. Filter: `mode` alone might be too generic, keep both

**Output:** `['mode', 'dark-mode']`

### Example 4: Hotfix with Tracker

**Input:** `hotfix/JIRA-789-security-patch`

**Processing:**

1. Parse: `JIRA-789-security-patch`
2. Remove tracker: `security-patch`
3. Split: `['security', 'patch']`
4. Generate: `['patch', 'security-patch']`

**Output:** `['patch', 'security-patch']`

### Example 5: Release Branch

**Input:** `release/v1.2.0`

**Processing:**

1. Parse: `v1.2.0`
2. No issue pattern
3. Split: `['v1', '2', '0']` (version parts)
4. Special case: Keep version as-is

**Output:** `['v1.2.0']`

## Edge Cases

### Single Word Description

**Input:** `feature/auth`

**Output:** `['auth']`

### Very Long Description

**Input:** `feature/issue-99-implement-oauth2-provider-integration-with-google`

**Output:** `['google', 'with-google', 'integration-with-google', 'provider-integration-with-google', 'oauth2-provider-integration']`

Note: Limit to 5 options maximum for usability.

### Already Short

**Input:** `bugfix/typo`

**Output:** `['typo']`

## Validation Rules

Generated directory names must be:

1. Lowercase only
2. Hyphens for word separation (no underscores)
3. No consecutive hyphens
4. No leading or trailing hyphens
5. Filesystem safe (no special characters)
6. Not reserved names (`main`, `master`, `develop`, `HEAD`)

## Integration

This skill is used by:

1. `/gitx:worktree` command - When creating worktrees
2. `/gitx:fix-issue` command - When setting up worktree in Phase 5
3. Any workflow that needs abbreviated directory naming

## Best Practices

1. **Prefer Semantic Names**: Choose the option that best describes the work
2. **Avoid Collisions**: Check existing worktrees before selecting
3. **Keep Short**: Shorter paths are easier to navigate
4. **Be Consistent**: Use similar abbreviation patterns across projects
