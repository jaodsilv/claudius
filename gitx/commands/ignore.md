---
description: Adds files or patterns to .gitignore when excluding from tracking. Use for build artifacts, secrets, or temp files.
argument-hint: "[PATTERNS...]"
allowed-tools: Read, Edit, Write, Bash(git:*), AskUserQuestion
model: haiku
---

# Add to .gitignore

Add one or more files or patterns to the repository's .gitignore file.

## Parse Arguments

From $ARGUMENTS, extract:

- Patterns: Space-separated list of files, directories, or glob patterns

If no patterns provided:

- Use AskUserQuestion: "What would you like to ignore?"
- Options:
  1. "Enter patterns manually" - User provides patterns
  2. "Ignore untracked files" - Show untracked files to select from
  3. "Common patterns" - Offer common ignore patterns

## Find .gitignore

Locate repository root:

- Get repo root: !`git rev-parse --show-toplevel`
- .gitignore path: `<repo-root>/.gitignore`

Check if .gitignore exists:

- If exists: Read current contents
- If not: Will create new file

## Process Patterns

For each pattern in the input:

### Validate Pattern

1. Check if pattern is already in .gitignore
2. Check if pattern matches existing tracked files

If pattern already exists:

- Skip with message: "Pattern already in .gitignore: [pattern]"

If pattern matches tracked files:

- Warn: "Pattern matches tracked files that won't be ignored until untracked"
- List affected files: `git ls-files -- <pattern>`
- Ask if user wants to untrack: `git rm --cached <files>`

### Normalize Pattern

- Directory patterns: Ensure trailing `/` for directories
- Relative paths: Convert to repo-relative paths
- Escape special characters if needed

## Apply Changes

Read current .gitignore (if exists):

- Use Read tool for .gitignore

Append patterns:

- Add blank line before new patterns if file doesn't end with newline
- Add comment with date: `# Added by gitx:ignore`
- Add each pattern on its own line

Write updated .gitignore:

- Use Edit tool to append, or Write tool if creating new file

## Confirmation

Show summary:

```text
## Patterns Added to .gitignore

- pattern1
- pattern2

### Already Existed (skipped)
- existing-pattern

### Warnings
- pattern3 matches tracked files (use `git rm --cached` to untrack)
```

## Error Handling

1. No patterns provided: Prompt for input.
2. Invalid pattern syntax: Report and skip.
3. Permission denied: Check file permissions.
4. Not a git repository: Report error.
