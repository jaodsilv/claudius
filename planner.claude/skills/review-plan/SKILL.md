---
description: Reviews plan files with multi-agent orchestration. Use for comprehensive plan quality analysis.
argument-hint: "[[--plan-path] <plan-path>] [--goal <goal>] [--mode <quick|thorough>]"
user-invocable: true
allowed-tools: Task, Read, Glob, Grep, Skill, AskUserQuestion, TodoWrite
model: opus
---

# /planner:review-plan

Reviews a plan file with multi-agent orchestration for comprehensive, multi-perspective analysis.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$plan_path`: Path to the plan file to review. First positional argument.
- `$goal`: Optional goal for alignment checking
- `$mode`: `thorough` (default) or `quick`

## Workflow

### 1. Load Skill

Invoke the Skill `planner:orchestrating-reviews` for multi-agent review orchestration.

### 2. Domain Context

**Artifact Type**: plan
**Primary Artifact Path**: `{{plan_path}}`
**Domain Reviewer Agent**: `planner:reviewers:plan-reviewer`
**Evaluation Dimensions**:

- Goal Alignment - Does plan support stated objectives?
- Completeness - Are all necessary sections present?
- Feasibility - Are timelines and resources realistic?
- Clarity - Is the plan unambiguous and actionable?
- Risk Coverage - Are risks identified and mitigated?

## Usage Examples

```text
/planner:review-plan docs/planning/roadmap.md
/planner:review-plan project-plan.md --mode quick
/planner:review-plan docs/plan.md --goal "Launch MVP by Q2"
```

## Error Handling

- File not found: Suggest similar paths via Glob
- Plan too large: Summarize sections before analysis
- Goal unclear: Ask user before evaluation
