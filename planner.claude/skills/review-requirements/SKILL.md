---
description: Reviews requirements quality with multi-agent orchestration. Use for validating completeness and testability.
argument-hint: "[[--goal] <goal> | [--roadmap-path] <roadmap-path>] [--requirements-path <path>] [--mode <quick|thorough>]"
user-invocable: true
allowed-tools: Task, Read, Glob, Grep, Skill, AskUserQuestion, TodoWrite
model: opus
---

# /planner:review-requirements

Reviews requirements document with multi-agent orchestration for quality, completeness, and testability.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$context`: Goal or path to roadmap file (required). It's value it the substring of everything that comes before any flags.
- `$requirements_path`: path to the requirements file (default: "docs/planning/requirements.md")
- `$mode`: How to review the requirements: "quick" or "thorough"

## Workflow

### 1. Load Skill

Invoke the Skill `planner:orchestrating-reviews` for multi-agent review orchestration.

### 2. Domain Context

**Artifact Type**: requirements
**Primary Artifact Path**: `$requirements_path`
**Domain Reviewer Agent**: `planner:reviewers:requirements-reviewer`
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
