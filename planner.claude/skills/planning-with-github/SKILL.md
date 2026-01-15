---

name: planner:planning-with-github
description: Integrates GitHub issues with project planning. Invoked when user asks to analyze issues, fetch issues for planning, map dependencies, or work with GitHub projects
---

# Planning with GitHub

Analyzes and processes GitHub issues for prioritization and roadmapping using the gh CLI.

## Prerequisites

- **GitHub CLI (gh)**: Required - `gh auth login` to authenticate
- **jq**: Optional - for advanced JSON filtering

## Core CLI Commands

```bash
# List open issues with planning data
gh issue list --state open --json number,title,labels,milestone,body,comments,createdAt,updatedAt

# Filter by label or milestone
gh issue list --label "feature" --milestone "v1.0" --json number,title,labels,body

# Get issue details with linked PRs
gh issue view <number> --json number,title,body,labels,comments,assignees,linkedPullRequests

# List milestones
gh api repos/{owner}/{repo}/milestones --jq '.[] | {number, title, due_on, open_issues, closed_issues}'
```

## Label Interpretation

### Priority Labels

| Pattern                    | Priority | MoSCoW      |
| -------------------------- | -------- | ----------- |
| `P0`, `critical`, `blocker`| Highest  | Must Have   |
| `P1`, `high-priority`      | High     | Should Have |
| `P2`, `medium`, `normal`   | Medium   | Could Have  |
| `P3`, `low`                | Low      | Could Have  |

### Status Labels

| Pattern              | Action              |
| -------------------- | ------------------- |
| `blocked`, `waiting` | Check blocker       |
| `ready`, `groomed`   | Can be scheduled    |
| `in-progress`, `wip` | Already worked      |
| `needs-triage`       | Requires triage     |

## Dependency Extraction

Parse issue body for dependency patterns:

```regex
blocked by #(\d+)
depends on #(\d+)
requires #(\d+)
blocks #(\d+)
```

Build dependency graph:
1. Extract patterns from body/comments
2. Identify root nodes (no blockers)
3. Find critical paths (longest chains)
4. Flag circular dependencies

## PR Status Interpretation

| Status    | Issue Impact      |
| --------- | ----------------- |
| No PR     | Not started       |
| Draft PR  | In progress       |
| Review PR | Near completion   |
| Merged PR | Can close issue   |

## Output Templates

### Issue Summary

```markdown
| # | Title | Priority | Effort | Status | Blocked By |
|---|-------|----------|--------|--------|------------|
```

### Dependency Report

```markdown
## Critical Path
#123 -> #125 -> #126 (3 issues, ~2 weeks)

## Ready Issues (No Blockers)
- #123, #124

## Blocked Issues
- #125 - Waiting on: #123, #124
```

## Best Practices

1. Use consistent labeling conventions
2. Document dependencies with standard patterns
3. Keep milestones updated
4. Link PRs to issues for status tracking
5. Run regular triage to close stale issues
