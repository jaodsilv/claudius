---
description: Reviews plan files with multi-agent orchestration. Use for comprehensive plan quality analysis.
allowed-tools: Task, Read, Glob, Grep, Skill, AskUserQuestion, TodoWrite
argument-hint: <plan-path> [--goal <goal>] [--mode <quick|thorough>]
---

# /planner:review-plan

Reviews a plan file with multi-agent orchestration for comprehensive, multi-perspective analysis.

## Parameters Schema

```yaml
review-plan-arguments:
  type: object
  properties:
    plan_path:
      type: string
      description: Path to the plan file to review
    goal:
      type: string
      description: Optional goal for alignment checking
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [plan_path]
```

## Workflow

### 1. Load Skill

Use Skill tool: `planner:orchestrating-reviews`

### 2. Domain Context

**Artifact Type**: plan
**Primary Artifact Path**: `{{plan_path}}`
**Domain Reviewer Agent**: `planner-plan-reviewer`
**Evaluation Dimensions**:

- Goal Alignment - Does plan support stated objectives?
- Completeness - Are all necessary sections present?
- Feasibility - Are timelines and resources realistic?
- Clarity - Is the plan unambiguous and actionable?
- Risk Coverage - Are risks identified and mitigated?

### 3. Execute Orchestration

Follow the orchestrating-reviews skill pattern with above context.

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
