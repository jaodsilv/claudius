---
description: Add files or patterns to .gitignore when excluding from tracking. Use for build artifacts, secrets, or temp files.
argument-hint: "[PATTERNS...]"
allowed-tools: AskUserQuestion, Skill(gitx:validating-gitignore-patterns:*)
model: sonnet
---

# Add to .gitignore (Script-First)

Add one or more files or patterns to the repository's .gitignore file.

## Parse Arguments

From $ARGUMENTS, extract patterns (space-separated).

If no patterns provided:

- Use AskUserQuestion: "What would you like to ignore?"
- Options: ["Enter patterns manually", "Ignore untracked files", "Common patterns"]

## Phase 1: Validate Patterns

Use `gitx:validating-gitignore-patterns` skill to validate patterns:

- patterns: `<patterns...>`

### Handle Exit 0 (Ready)

Patterns validated successfully. Continue to execute.

### Handle Exit 1 (Tracked Conflicts)

Show conflicts and ask:

```text
AskUserQuestion:
  Question: "These files are tracked and match the patterns. Untrack them?"
  Options:
  - "Untrack and ignore" - Remove from git index, keep files
  - "Skip conflicting patterns" - Only add non-conflicting
  - "Cancel" - Don't modify .gitignore
```

### Handle Exit 2 (Error)

Report error from JSON output.

## Phase 2: Execute

Use `gitx:validating-gitignore-patterns` skill to execute:

- patterns: `<patterns...>`
- execute: true
- untrack: (if user chose to untrack conflicting files)

## Phase 3: Report

From JSON output, show:

- Patterns added
- Patterns skipped (already existed)
- Files untracked (if applicable)
