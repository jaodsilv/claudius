---
name: gitx:naming-branches
description: >-
  Applies project-specific branch naming conventions for this repository.
  Invoked when creating branches, worktrees, or validating branch names.
  Use when needing project-specific patterns or workflow integration rules.
allowed-tools: AskUserQuestion
context: fork
model: opus
---

# Naming Branches

Claude already knows standard conventions (feature/, bugfix/, hotfix/, release/) and should use them when appropriate.

## Input

Identify from your input prompt if you were provided:

- issue number
- issue labels
- issue title
- description

You will be provided with an input string. Your task is to create a branch names based on that input, here referenced as `$input`.

## Branch Type Selection

### From Issue Information

#### From Issue Labels

Map GitHub issue labels to branch types:

| Label | Branch Type |
|-------|-------------|
| bug | bugfix/ |
| feature, enhancement | feature/ |
| documentation | docs/ |
| refactor | refactor/ |
| hotfix, critical | hotfix/ |
| (no label) | Evaluate by title |

#### From Issue Title

If no labels, infer from keywords:

- "fix", "bug", "error", "crash" -> bugfix/
- "add", "implement", "new" -> feature/
- "update docs", "readme" -> docs/
- Otherwise -> Ultrathink to evaluate

#### Branch Name Format

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

### From Task Descriptions

When no issue number:

```text
<type>/<slugified-description>
```

**Example**: "add user authentication" -> `feature/add-user-authentication`

## Name Generation and Selection

Using the information and rules above and Conventional Branch names, generate 3 meaningful names for the given input. They must pass the validation checklist below.

### Validation Checklist

Before creating a branch, verify:

- [ ] Type prefix matches change nature
- [ ] Uses lowercase letters, numbers, hyphens only
- [ ] No consecutive, leading, or trailing hyphens
- [ ] Issue number included (if applicable)
- [ ] Total length under 50 characters

### Selection Flow

After generating 3 name options:

1. Present options to user via AskUserQuestion
2. If user types custom name, validate with the rules above.
   1. If invalid, explain why and ask for a new name
3. Confirm final branch name with user
4. Output the user choice as the result

## Integration with Conventional Commits

Branch names guide commit scopes:

```text
# Branch: feature/issue-123-user-auth
# Commits:
feat(auth): implement OAuth2 login
test(auth): add authentication tests
```
