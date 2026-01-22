---
name: gitx:naming-worktrees
description: >-
  Generates abbreviated worktree directory names from branch names.
  Invoked when creating worktrees to offer short, meaningful options.
allowed-tools: AskUserQuestion, Bash(scripts/generate-worktree-names.sh:*), Skill(gitx:validating-directory-names:*)
context: fork
model: sonnet
---

# Naming Worktrees

Generate abbreviated directory names from conventional branch names.

## Execution

Run the name generation script:

```bash
scripts/generate-worktree-names.sh <branch_name>
```

### Script Output

Returns JSON with suggested names and paths:

```json
{
  "branch": "feature/issue-123-add-user-auth",
  "parent_dir": "/d/src/project",
  "options": [
    {"name": "auth", "path": "/d/src/project/auth"},
    {"name": "user-auth", "path": "/d/src/project/user-auth"},
    {"name": "add-user-auth", "path": "/d/src/project/add-user-auth"}
  ]
}
```

## Selection Flow

After getting options from the script:

1. Present options to user via AskUserQuestion
2. If user types custom name, validate with the Skill `gitx:validating-directory-names`
3. Confirm final path with user
4. Output the user choice as the result
