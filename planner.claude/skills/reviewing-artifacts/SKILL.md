---
name: planner:reviewing-artifacts
description: >-
  Provides standard review process for planning artifacts with dimension-based
  scoring. Use when evaluating plans, requirements, architecture, or other
  planning documents against goals and quality criteria.
model: sonnet
---

# Reviewing Artifacts

## How to Invoke This Skill

Use the Skill tool to load this skill:

```
Invoke the Skill `planner:reviewing-artifacts` for artifact review guidance.
```

Or from agents, use the Task tool:

```
Task(planner:reviewing-artifacts)
```

The skill provides standard evaluation formats, dimension scoring, and interactive refinement patterns for reviewing planning artifacts.

## Review Process

1. **Read the Artifact**: Understand goal, map structure, note key decisions, identify gaps
2. **Gather Context**: Read goal statement, success criteria, constraints
3. **Systematic Evaluation**: Score each dimension 1-5 with specific findings
4. **Gap Analysis**: Identify what's missing and impact
5. **Generate Report**: Use review-report template
6. **Interactive Discussion**: Present findings, iterate on suggestions

## Dimension Scoring (1-5 Scale)

| Score | Meaning                                  |
| ----- | ---------------------------------------- |
| 5     | Excellent - exceeds expectations         |
| 4     | Good - meets expectations                |
| 3     | Adequate - acceptable with minor issues  |
| 2     | Poor - significant gaps                  |
| 1     | Inadequate - major revision needed       |

## Standard Evaluation Format

```markdown
### [Dimension]: [Score]/5

**Strengths**:
- [Specific strength with evidence]

**Concerns**:
- [Specific concern with location]

**Suggestions**:
- [Actionable improvement]
```

## Gap Analysis Format

| Gap               | Impact               | Suggested Resolution |
| ----------------- | -------------------- | -------------------- |
| [Missing element] | [Impact on artifact] | [How to address]     |

## Interactive Refinement

1. Present findings - start with critical issues
2. Explain rationale for concerns
3. Offer specific improvements
4. Ask if user wants clarification
5. Iterate on suggestions
6. Summarize agreed changes

## Guidelines

- Be constructive, not critical
- Provide specific, actionable feedback
- Acknowledge strengths before weaknesses
- Prioritize feedback by impact
- Keep the goal in focus
