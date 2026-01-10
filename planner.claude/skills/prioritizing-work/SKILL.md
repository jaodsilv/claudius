---
name: planner:prioritizing-work
description: Applies prioritization frameworks to rank items. Invoked when user asks to prioritize issues, rank features, apply RICE/MoSCoW scoring, or create priority matrices.
allowed-tools: Bash
model: sonnet
---

# Prioritizing Work

Applies RICE, MoSCoW, Weighted Scoring, Kano, or Value vs Effort frameworks to rank items systematically.

## Prerequisites

- **GitHub CLI (gh)**: Required for GitHub issue integration

## Framework Selection

| Framework        | Best For                          |
| ---------------- | --------------------------------- |
| RICE             | Data-driven product decisions     |
| MoSCoW           | Stakeholder-driven prioritization |
| Weighted Scoring | Custom criteria evaluation        |
| Kano Model       | User satisfaction analysis        |
| Value vs Effort  | Quick visual prioritization       |

## GitHub Label Mapping

For GitHub label conventions (priority, effort), see `planner:planning-with-github` skill.

## GitHub CLI Commands

```bash
# Get all open issues
gh issue list --json number,title,labels,body,comments,milestone

# Get specific issue
gh issue view <number> --json number,title,body,labels,state
```

## Output Templates

### RICE Matrix

```markdown
| Rank | Item | Reach | Impact | Confidence | Effort | Score |
| ---- | ---- | ----- | ------ | ---------- | ------ | ----- |
| 1    | ...  | ...   | ...    | ...        | ...    | ...   |
```

### MoSCoW Categories

```markdown
## Must Have (Critical) - max 60% effort
1. [Item] - [Rationale]

## Should Have (Important) - ~20% effort
1. [Item] - [Rationale]

## Could Have (Desirable) - ~20% effort
1. [Item] - [Rationale]

## Won't Have (This Release)
1. [Item] - [Reason]
```

## Best Practices

1. Document rationale for each ranking
2. Parse issue body for dependencies ("blocked by #X")
3. Use milestone for timeline constraints
4. Involve stakeholders before finalizing
5. Re-prioritize when conditions change
