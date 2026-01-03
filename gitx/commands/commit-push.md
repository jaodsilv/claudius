---
description: Commits staged changes and pushes to remote when saving work. Use for standard git workflow or quick updates.
argument-hint: ""
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*)
---

# Commit and Push

Commit all changes with a well-crafted message following conventional commits, then push to remote.

## Gather Context

Get repository state:

- Current branch: !`git branch --show-current`
- Untracked files: !`git status --porcelain`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits (for style reference): !`git log --oneline -10`

## Analyze Changes

Review all changes to understand what's being committed:

- `git diff HEAD` to see full changes
- Identify the nature: new feature, bug fix, refactor, docs, etc.
- Look for patterns in file names and content

## Draft Commit Message

Use the gitx:committing-conventionally skill to draft an appropriate message:

1. Determine type:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `style:` for formatting
   - `refactor:` for code restructuring
   - `test:` for tests
   - `chore:` for maintenance

2. Determine scope (optional):
   - Based on affected component/module
   - e.g., `feat(auth):`, `fix(api):`

3. Write description:
   - Imperative mood ("add" not "added")
   - Concise but descriptive
   - No period at end

4. Add body if needed:
   - Explain the "why" for non-trivial changes
   - Reference related issues

## Stage Changes

Stage relevant files:

- Analyze which files should be committed
- Avoid committing sensitive files (.env, credentials, etc.)
- `git add <files>` for specific files
- If all changes are intentional: `git add -A`

## Create Commit

Commit with the drafted message:

```text
git commit -m "<type>(<scope>): <description>

<body if needed>

<footer if needed>"
```

## Push to Remote

Push the commit:

1. Check if remote tracking branch exists: `git rev-parse --abbrev-ref @{upstream} 2>/dev/null`
2. If exists: `git push`
3. If not exists: `git push -u origin <branch-name>`

## Report Results

Show:

- Commit hash and message
- Files changed
- Push status
- Branch URL (if available): `https://github.com/<owner>/<repo>/tree/<branch>`

## Error Handling

1. No changes to commit: Report "Nothing to commit, working tree clean".
2. Push rejected (behind remote): Suggest `git pull --rebase` first.
3. Push rejected (no permission): Check authentication.
4. Pre-commit hook failed: Report failure and do NOT amend, create new commit after fix.
