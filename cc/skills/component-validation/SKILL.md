---
name: cc:component-validation
description: >-
  Provides validation criteria for Claude Code plugin components. Use when validating
  commands, agents, skills, orchestrations, or output-styles against best practices.
  Load this skill during component creation or improvement workflows.
version: 1.0.0
---

# Component Validation

Validation criteria and quality standards for Claude Code plugin components.

## Quick Reference

| Component | Key Validations | Reference |
|-----------|-----------------|-----------|
| Command | description <60 chars, allowed-tools minimal, FOR Claude style | `references/command-criteria.md` |
| Agent | 2-4 examples, 500-3000 word prompt, clear role | `references/agent-criteria.md` |
| Skill | third-person description, 1500-2000 words, progressive disclosure | `references/skill-criteria.md` |
| Orchestration | phase gates, data flow, error recovery | `references/orchestration-criteria.md` |
| Output-Style | formatting rules, tone definition, examples | `references/output-style-criteria.md` |

## Universal Criteria

All components must satisfy:

1. **Valid frontmatter**: YAML syntax correct, required fields present
2. **Clear purpose**: Single, well-defined responsibility
3. **Appropriate naming**: Kebab-case, descriptive, 3-50 characters
4. **No security issues**: No credential exposure, minimal permissions

## Validation Process

1. Parse frontmatter and check syntax
2. Validate required fields present
3. Check component-specific criteria
4. Verify references exist (if applicable)
5. Assess quality against best practices
6. Generate severity-categorized findings

## Severity Assignment

Assign severity based on impact:

| Severity | Criteria |
|----------|----------|
| CRITICAL | Prevents component from functioning, security vulnerability |
| HIGH | Best practice violation affecting quality or maintainability |
| MEDIUM | Enhancement opportunity, suboptimal but functional |
| LOW | Polish, style consistency, minor improvements |

## Component-Specific Criteria

Detailed criteria for each component type:

- **`references/command-criteria.md`** - Command validation rules
- **`references/agent-criteria.md`** - Agent validation rules
- **`references/skill-criteria.md`** - Skill validation rules
- **`references/orchestration-criteria.md`** - Orchestration validation rules
- **`references/output-style-criteria.md`** - Output-style validation rules
