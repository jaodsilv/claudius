---
name: brainstorm:requirements-synthesis
description: >-
  Consolidates brainstorming insights into structured requirements. Use when formulating requirements, prioritizing features, or validating requirement quality.
allowed-tools:
model: sonnet
---

# Requirements Synthesis

Consolidates brainstorming insights into structured requirements. Use when formulating requirements,
prioritizing features, or validating requirement quality.

## When to Use

- After gathering user needs to formalize requirements
- When prioritizing features for a release
- To validate requirement quality and completeness
- During Phase 5 of the brainstorming workflow

## Requirement Categories

- **Functional requirements**: Core features and capabilities
- **Non-functional requirements**: Performance, security, scalability, usability, reliability
- **Constraints**: Technical, business, regulatory, and resource limitations
- **Assumptions**: Technical, business, and user behavior assumptions with risk assessment

## Quality Criteria

Reference `references/smart-criteria.md` for the SMART validation framework:
- **S**pecific: Unambiguous and clear
- **M**easurable: Can be verified and tested
- **A**chievable: Technically feasible
- **R**elevant: Aligned with project goals
- **T**ime-bound: Has clear scope and definition

## Prioritization

Reference `references/moscow-guide.md` for MoSCoW prioritization:
- **P1 Must Have**: Essential for MVP/release
- **P2 Should Have**: Important, not critical
- **P3 Could Have**: Desirable if time permits
- **P4 Won't Have**: Explicitly out of scope

## Output Format

Provide a structured summary:

```text
# Requirements Specification

## Executive Summary
- Name: [Product/Feature]
- Problem: [1-2 sentences]
- Users: [Primary segments]
- Value: [Key benefit]

## Functional Requirements (by priority)
## Non-Functional Requirements (organized by category)
## Constraints (with impact assessment)
## Assumptions (with risk identification)
## Out of Scope
## Dependency Map
## Gaps and Open Questions
## Traceability Matrix
```

## Writing Standards

1. Use active voice ("The system shall...")
2. One requirement per statement
3. Avoid ambiguous terms (fast, easy, user-friendly)
4. Include measurable acceptance criteria
5. Cross-reference related requirements

## Synthesis Process

1. **Gather**: Collect all brainstorming phase outputs
2. **Categorize**: Group related information
3. **Formulate**: Write clear requirement statements
4. **Prioritize**: Apply MoSCoW methodology
5. **Validate**: Check SMART criteria for each requirement
6. **Cross-reference**: Map dependencies between requirements
7. **Gap Analysis**: Identify missing information
8. **Review**: Final consistency check
