---
name: gitx:orchestrating-conflict-resolution
description: >-
  Orchestrates multi-agent conflict resolution workflow for merge and rebase
  operations. Use when git conflicts occur during branch integration.
version: 1.0.0
allowed-tools: Bash(git:*), Task, AskUserQuestion
model: opus
---

# Orchestrating Conflict Resolution

Multi-agent workflow for resolving git conflicts during merge/rebase operations.

## Input Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `$base_branch` | Branch being merged/rebased onto | `main`, `develop` |
| Operation type | Whether merge or rebase is in progress | `merge`, `rebase` |

## 5-Phase Workflow

### Phase 1: Conflict Analysis

Get conflict status and launch analyzer:

```bash
git status --porcelain | grep "^UU\|^AA\|^DD"
git diff --name-only --diff-filter=U
```

Launch conflict-analyzer agent:

```text
Task (gitx:conflict-resolver:conflict-analyzer):
  Operation: [merge|rebase]
  Base Branch: $base_branch
  Conflicting Files: [list from git status]

  Analyze each conflict:
  - What both sides changed
  - Why they conflict
  - Semantic vs syntactic conflict
  - Recommended resolution strategy
```

### Phase 2: Resolution Suggestions

Launch resolution-suggester agent:

```text
Task (gitx:conflict-resolver:resolution-suggester):
  Conflict Analysis: [output from Phase 1]

  For each conflict:
  - Generate specific resolution code
  - Provide confidence level
  - Note verification steps
```

### Phase 3: User-Guided Resolution

Present options for each conflict using AskUserQuestion.
See [references/resolution-options.md](references/resolution-options.md) for details.

After each resolution: `git add <file>`

### Phase 4: Validation

Launch merge-validator agent:

```text
Task (gitx:conflict-resolver:merge-validator):
  Resolved Files: [list]
  Operation: [merge|rebase]

  Validate:
  - No remaining conflict markers
  - Syntax is valid
  - Types check (if applicable)
```

If validation fails, report issues and allow fixing before continuing.

### Phase 5: Continue Operation

When all conflicts resolved and validated:

- **Rebase**: `git rebase --continue`
- **Merge**: Create merge commit with resolution summary

If more conflicts occur (during subsequent rebase commits), repeat Phases 1-5.
