---
description: Reviews roadmaps with multi-agent orchestration against a goal. Use for validating roadmap alignment.
argument-hint: "[[--goal] <goal>] [--roadmap-path <path>] [--mode <quick|thorough>]"
allowed-tools: Agent, Read, Glob, Grep, Skill, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate
model: opus
---

# /planner:review-roadmap

Reviews a roadmap with multi-agent orchestration for alignment with a goal and overall quality.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$goal`: required. Goal to evaluate roadmap against (required). It's value it the substring of everything that comes before any flags.
- `$roadmap_path`: Path to the roadmap. (default: "docs/planning/roadmap.md")
- `$mode`: How to review the roadmap: "thorough" (default) or "quick"

## Workflow

### 1. Load Skill

Invoke the Skill `planner:orchestrating-reviews` for multi-agent review orchestration.

### 2. Domain Context

**Artifact Type**: roadmap
**Primary Artifact Path**: `$roadmap_path`
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
