---
name: gitx:validating-directory-names
description: >-
  Validates custom directory names for worktrees. Use when users provide custom
  names for worktree directories to ensure filesystem compatibility.
version: 1.0.0
allowed-tools: Bash(git worktree:*)
model: haiku
---

# Validating Directory Names

Validate custom directory names for worktree creation.

## Format Rules

Valid names must:

- Use lowercase only (a-z)
- Use hyphens for word separation (no underscores)
- No consecutive hyphens
- No leading or trailing hyphens
- No special characters or spaces

## Length Rules

| Condition | Action |
|-----------|--------|
| < 2 chars | Reject - "Name too short (min 2 chars)" |
| > 30 chars | Reject - "Name too long (max 30 chars)" |
| 2-30 chars | Pass validation |

## Reserved Names

Reject these names outright:

- **Git**: main, master, develop, HEAD, origin
- **System**: tmp, temp, test, build, dist, node_modules

## Collision Check

Before accepting a name:

1. Get existing worktrees: `git worktree list`
2. Extract directory names from paths
3. If collision exists: "Directory already exists"

## Error Messages with Suggestions

| Error | Suggestion |
|-------|------------|
| Contains uppercase | Suggest lowercase version |
| Contains underscores | Suggest hyphens version |
| Too long | Suggest truncated at 30 chars |
| Reserved name | Suggest `<name>-dev` alternative |
| Directory exists | Suggest numeric suffix (`<name>-2`) |

## Return Values

| Result | Next Step |
|--------|-----------|
| Pass | Proceed with directory creation |
| Fail | Return error with suggestion |
