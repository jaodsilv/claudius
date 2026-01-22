---
name: gitx:validating-gitignore-patterns
description: >-
  Scripts for validating and adding gitignore patterns with conflict detection.
  Invoked when adding patterns to .gitignore.
allowed-tools: Bash(scripts/validate-patterns.sh:*), Bash(scripts/gitignore-add.sh:*)
model: sonnet
---

# Validating Gitignore Patterns

Validate and add patterns to .gitignore with duplicate detection, tracked file conflicts, and normalization.

## Scripts

### validate-patterns.sh

Validates patterns for conflicts and duplicates.

```bash
scripts/validate-patterns.sh "<repo_root>" "<pattern1>" ...
```

### gitignore-add.sh

Validates and adds patterns to .gitignore.

```bash
scripts/gitignore-add.sh <patterns...> [options]
```

**Options**: `--execute`, `--untrack`

**Exit codes**: 0 ready, 1 tracked file conflicts, 2 error

## Two-Phase Pattern

1. **Validate**: Check for duplicates and tracked file conflicts
2. **Execute**: Add patterns (with `--execute`), optionally untrack files (with `--untrack`)
