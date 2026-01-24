---
description: Reviews roadmaps with multi-agent orchestration against a goal. Use for validating roadmap alignment.
allowed-tools: Task, Read, Glob, Grep, Skill, AskUserQuestion, TodoWrite
argument-hint: <goal> [--roadmap-path <path>] [--mode <quick|thorough>]
model: opus
---

# /planner:review-roadmap

Reviews a roadmap with multi-agent orchestration for alignment with a goal and overall quality.

## Parameters Schema

```yaml
review-roadmap-arguments:
  type: object
  properties:
    goal:
      type: string
      description: Goal to evaluate roadmap against
    roadmap_path:
      type: string
      default: "docs/planning/roadmap.md"
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [goal]
```

## Workflow

### 1. Load Skill

Invoke the Skill `planner:orchestrating-reviews` for multi-agent review orchestration.

### 2. Domain Context

**Artifact Type**: roadmap
**Primary Artifact Path**: `{{roadmap_path}}` (default: `docs/planning/roadmap.md`)
**Domain Reviewer Agent**: `planner:reviewers:plan-reviewer` (roadmap mode)
**Evaluation Dimensions**:

- Goal Alignment - Does each phase contribute to the goal?
- Phase Structure - Are phases logically sequenced with clear boundaries?
- Timeline - Are estimates realistic with appropriate buffers?
- Dependencies - Are inter-phase dependencies correctly mapped?
- Risk Coverage - Are timeline and dependency risks addressed?

## Usage Examples

```text
/planner:review-roadmap "Implement user authentication by Q2"
/planner:review-roadmap "Launch mobile app" --mode quick
/planner:review-roadmap "Scale to 1M users" --roadmap-path docs/scaling-roadmap.md
```

## Error Handling

- Goal not provided: Prompt user for goal
- Roadmap not found: Search with Glob, present options
- Empty roadmap: Report no content to review
