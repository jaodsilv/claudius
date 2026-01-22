---
description: Reviews requirements quality with multi-agent orchestration. Use for validating completeness and testability.
allowed-tools: Task, Read, Glob, Grep, Skill, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--requirements-path <path>] [--mode <quick|thorough>]
model: opus
---

# /planner:review-requirements

Reviews requirements document with multi-agent orchestration for quality, completeness, and testability.

## Parameters Schema

```yaml
review-requirements-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to roadmap file
    requirements_path:
      type: string
      default: "docs/planning/requirements.md"
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [context]
```

## Workflow

### 1. Load Skill

Invoke the Skill `planner:orchestrating-reviews` for multi-agent review orchestration.

### 2. Domain Context

**Artifact Type**: requirements
**Primary Artifact Path**: `{{requirements_path}}` (default: `docs/planning/requirements.md`)
**Domain Reviewer Agent**: `planner:planner:requirements-reviewer`
**Evaluation Dimensions**:

- Clarity - Is each requirement specific and unambiguous?
- Completeness - Are functional and non-functional requirements covered?
- Testability - Can each requirement be verified?
- Consistency - Are there no conflicting requirements?
- Traceability - Can requirements be linked to goals and tests?

## Usage Examples

```text
/planner:review-requirements "Launch MVP by Q2"
/planner:review-requirements docs/roadmap.md --mode quick
/planner:review-requirements "API v2" --requirements-path docs/api-v2/requirements.md
```

## Error Handling

- Requirements not found: Suggest `/planner:gather-requirements`
- User unresponsive during refinement: Save progress for resume
- Agent timeout: Report partial results
