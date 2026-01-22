---
name: review-loop:extending-loop-metadata
description: >-
  Extends gitx PR metadata with review-loop orchestration fields. Use when
  initializing, pausing, resuming, or completing a review loop session.
version: 1.0.0
dependencies:
  - gitx:managing-pr-metadata
---

# Review Loop Metadata Extension

Extends gitx's `.thoughts/pr/metadata.yaml` with review-loop orchestration state.

## Schema Extension

Add these fields to existing metadata:

```yaml
# In .thoughts/pr/metadata.yaml
reviewLoop:
  active: true                    # Is loop currently running?
  maxRounds: 5                    # Max iterations allowed
  startedAt: "2024-01-15T10:30:00Z"  # ISO8601 timestamp
  pausedAt: null                  # Set when paused, null when active

  # Agent configuration
  reviewer: "gitx:review:reviewer"        # Required
  developer: "gitx:address-review:review-responder"  # Required
  ciChecker: "gitx:address-review:ci-status-checker" # Optional
  ciFixer: "gitx:address-review:ci-status-fixer"     # Optional

  # Prompts file reference (to avoid metadata bloat)
  promptsFile: ".thoughts/review-loop/prompts.yaml"  # Optional
```

## Prompts File Schema

Store prompts separately in `.thoughts/review-loop/prompts.yaml`:

```yaml
reviewer: |
  Review the PR focusing on code quality...
developer: |
  Address the review comments...
ciChecker: |
  Check CI status and report failures...
ciFixer: |
  Fix CI failures...
noHandingOver: false              # Disable context passing between rounds
```

## Operations

All operations use `gitx:managing-pr-metadata` skill transparently.

### Initialize Loop

Use `gitx:managing-pr-metadata` skill to add reviewLoop fields:

- worktree: `<worktree>`
- field: reviewLoop
- value: `{"active": true, "maxRounds": 5, "startedAt": "...", "pausedAt": null, "reviewer": "...", "developer": "..."}`

### Check Loop Active

Use `gitx:managing-pr-metadata` skill to read reviewLoop.active:

- worktree: `<worktree>`
- field: reviewLoop.active
- operation: read

Returns: true or false

### Pause Loop

Use `gitx:managing-pr-metadata` skill to update fields:

1. Set reviewLoop.pausedAt to current timestamp
2. Set reviewLoop.active to false

### Resume Loop

Use `gitx:managing-pr-metadata` skill to update fields:

1. Set reviewLoop.pausedAt to null
2. Set reviewLoop.active to true

### Complete Loop

Use `gitx:managing-pr-metadata` skill:

1. Set reviewLoop.active to false
2. Optionally remove entire reviewLoop section when done

## Integration with gitx Metadata

### Fields Already Available (from gitx)

| Field | Type | Description |
|-------|------|-------------|
| `turn` | string | Current phase: REVIEW, RESPONSE, CI-PENDING, CI-REVIEW |
| `approved` | boolean | Loop exit condition |
| `resolveLevel` | string | Approval threshold: all, critical, important |
| `latestReviews` | array | Non-minimized reviews with timestamps/authors |
| `latestComments` | array | Developer responses to reviews |
| `reviewCount` | number | Number of review rounds completed |
| `ciStatus` | array | CI check results with status/conclusion |
| `latestCommit` | string | Current HEAD SHA |
| `reviewDecision` | string | GitHub approval status |

### Turn State Machine

The `turn` field (managed by gitx) determines which phase to execute:

```
CI-PENDING → CI checks still running, wait
CI-REVIEW  → CI failed, run ciFixer agent
REVIEW     → Ready for review, run reviewer agent
RESPONSE   → Review done, run developer agent
```

After RESPONSE phase, turn returns to REVIEW (or CI-* if CI enabled).

## Directory Structure

```
.thoughts/
├── pr/
│   └── metadata.yaml           # gitx metadata + reviewLoop extension
└── review-loop/
    └── prompts.yaml            # Stored prompts (optional)
```

## Example: Full Metadata with Extension

```yaml
# .thoughts/pr/metadata.yaml (with review-loop extension)
pr: 123
branch: feature/my-branch
author: johndoe
title: "Add new feature"
base: main

# Review state (from gitx)
turn: REVIEW
approved: false
resolveLevel: all
reviewCount: 2
latestCommit: "abc123"
reviewDecision: CHANGES_REQUESTED

latestReviews:
  - nodeid: "PRRT_123"
    body: "Please fix the error handling..."
    author: reviewer1
    timestamp: "2024-01-15T11:00:00Z"

latestComments:
  - nodeid: "IC_456"
    body: "Fixed error handling as requested..."
    author: johndoe
    timestamp: "2024-01-15T11:30:00Z"

ciStatus:
  - name: "tests"
    status: COMPLETED
    conclusion: SUCCESS

# Review loop extension
reviewLoop:
  active: true
  maxRounds: 5
  startedAt: "2024-01-15T10:30:00Z"
  pausedAt: null
  reviewer: "gitx:review:reviewer"
  developer: "gitx:address-review:review-responder"
  ciChecker: "gitx:address-review:ci-status-checker"
  ciFixer: "gitx:address-review:ci-status-fixer"
  promptsFile: ".thoughts/review-loop/prompts.yaml"

updatedAt: "2024-01-15T11:35:00Z"
```
