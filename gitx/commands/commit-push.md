---
description: Commits staged changes and pushes to remote when saving work. Use for standard git workflow or quick updates.
argument-hint: ""
allowed-tools: Skill(gitx:committing-and-pushing:*), Skill(gitx:committing-conventionally:*)
model: sonnet
---

# Commit and Push (Script-First)

Commit changes with a well-crafted message following conventional commits, then push to remote.

## Phase 1: Gather Context

Use `gitx:committing-and-pushing` skill to gather info:

- operation: info

### Handle Exit 1 (Nothing to commit)

Report: "Nothing to commit, working tree clean" and exit.

### Handle Exit 0 (Changes found)

Continue with JSON output containing staged files, diff summary, and recent commits.

## Phase 2: Draft Commit Message

Using the JSON output from Phase 1, apply skill `gitx:committing-conventionally`:

- Analyze `staged_files` to understand what changed
- Reference `recent_commits` for style consistency
- Draft message following conventional commits format

## Phase 3: Execute

Use `gitx:committing-and-pushing` skill to commit and push:

- message: `$message`
- all: true
- push: true

## Phase 4: Report Results

From JSON output, show:

- Commit hash and message
- Files changed
- Push status
- Branch URL (if available)

## Error Handling

1. Push rejected (behind remote): Suggest `git pull --rebase` first.
2. Pre-commit hook failed: Report failure and suggest fix.
