---
description: Reviews prioritization alignment with multi-agent orchestration. Use for validating issue rankings against goals.
argument-hint: "<goal|roadmap-path> [--prioritization-path <path>] [--mode <quick|thorough>]"
user-invocable: true
allowed-tools: Task, Read, Glob, Grep, Bash, Skill, AskUserQuestion, TodoWrite
model: opus
---

# /planner:review-prioritization

Reviews issue prioritization with multi-agent orchestration for alignment with a goal or roadmap.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$context`: Goal or path to roadmap file (required). It's value it the substring of everything that comes before any flags.
- `$prioritization_path`: path to the priorities file (default: "docs/planning/priorities.md")
- `$mode`: How to review the requirements: "quick" or "thorough"

## Workflow

### 1. Load Skill

Invoke the Skill `planner:orchestrating-reviews` for multi-agent review orchestration.

### 2. Domain Context

**Artifact Type**: prioritization
**Primary Artifact Path**: `{{prioritization_path}}` (default: `docs/planning/prioritization.md`)
**Domain Reviewer Agent**: `planner:reviewers:plan-reviewer`
**Evaluation Dimensions**:

- Framework Application - Is the prioritization framework consistently applied?
- Scoring Rationale - Do scores have clear justification?
- Dependency Handling - Are dependencies reflected in priority order?
- Bias Check - Are there over/under-prioritized items?

## Usage Examples

```text
/planner:review-prioritization "Ship MVP by end of month"
/planner:review-prioritization docs/roadmap.md --mode quick
/planner:review-prioritization "API v2" --prioritization-path docs/api-v2/priorities.md
```

## Error Handling

- Context not provided: Prompt user for goal or roadmap path
- Prioritization file not found: Search with Glob, present options
- Agent timeout: Report partial results
