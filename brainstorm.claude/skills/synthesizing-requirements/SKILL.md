---
description: >-
  Consolidates brainstorming insights into structured requirements. Use when formulating requirements, prioritizing features, or validating requirement quality.
  Also use after gathering user needs to formalize requirements or during Phase 5 of the brainstorming workflow.
user-invocable: false
allowed-tools:
model: sonnet
---

# Requirements Synthesis

Consolidates brainstorming insights into structured requirements. Use when formulating requirements,
prioritizing features, or validating requirement quality.

## Requirement Categories

- **Functional requirements**: Core features and capabilities
- **Non-functional requirements**: Performance, security, scalability, usability, reliability
- **Constraints**: Technical, business, regulatory, and resource limitations
- **Assumptions**: Technical, business, and user behavior assumptions with risk assessment

## Quality Criteria

Reference `${CLAUDE_SKILL_DIR}/references/smart-criteria.md` for the SMART validation framework:

- **S**pecific: Unambiguous and clear
- **M**easurable: Can be verified and tested
- **A**chievable: Technically feasible
- **R**elevant: Aligned with project goals
- **T**ime-bound: Has clear scope and definition

## Prioritization

Reference `${CLAUDE_SKILL_DIR}/references/moscow-guide.md` for MoSCoW prioritization:

- **P1 Must Have**: Essential for MVP/release
- **P2 Should Have**: Important, not critical
- **P3 Could Have**: Desirable if time permits
- **P4 Won't Have**: Explicitly out of scope

## Output Format

**Full output**: Provide a structured summary filling the template file
`${CLAUDE_SKILL_DIR}/references/output-template.md`. Depending on the request, it may be output to a file.
**Compact Output**: In addition to the full output, provide a compact summary (10-15 lines) direct to the user.
For that use the template from the `### Compact Output Template` section.

### Compact Output Template

```markdown
- **Requirements count**: [X functional, Y non-functional, Z constraints]
- **Priority breakdown**: [P1: X, P2: Y, P3: Z]
- **Key dependencies**: [Top 3 critical dependencies]
- **Gaps identified**: [Major gaps requiring follow-up]
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
