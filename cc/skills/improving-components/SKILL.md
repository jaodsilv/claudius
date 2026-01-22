---
name: cc:improving-components
description: >-
  Provides interactive improvement workflows for plugin components when analyzing
  and enhancing commands, agents, skills, or orchestrations. Use when implementing
  analyze-suggest-approve-apply patterns or severity-based improvement workflows.
version: 1.0.0
allowed-tools: Read, Edit, AskUserQuestion
model: sonnet
---

# Improving Components

Guidelines for interactive improvement workflows in Claude Code plugins.

## Workflow Phases

1. **Analysis**: Read component, apply criteria, categorize by severity
2. **Presentation**: Show grouped suggestions to user
3. **Approval**: Get user selection via AskUserQuestion
4. **Application**: Apply approved changes, validate, report

## Severity Levels

| Level | Description | Examples |
|-------|-------------|----------|
| CRITICAL | Breaks functionality/security | Invalid syntax, missing fields, vulnerabilities |
| HIGH | Best practice violations | Missing examples, wrong style, permissive tools |
| MEDIUM | Enhancement opportunities | Incomplete docs, suboptimal organization |
| LOW | Polish and refinement | Style consistency, minor wording |

## Approval Patterns

### Batch by Severity

```text
Question: "Which severity levels would you like to address?"
Header: "Severity"
multiSelect: true
Options:
- CRITICAL (X issues) - Must fix for functionality
- HIGH (X issues) - Best practice violations
- MEDIUM (X issues) - Enhancement opportunities
- LOW (X issues) - Polish and refinement
```

### Individual Selection

```text
Question: "Which improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List of specific improvements]
```

## Analysis Output Format

```markdown
## Analysis Summary

### Component: [name]
### Type: [command|agent|skill|orchestration]
### Overall Quality: [assessment]

### Suggestions by Severity

#### CRITICAL
1. [Issue]: [Specific fix]

#### HIGH
1. [Issue]: [Specific fix]
...
```

## Application Checklist

- [ ] Show before/after for significant changes
- [ ] Apply changes using Edit tool
- [ ] Validate syntax after each edit
- [ ] Report success/failure per change
- [ ] Present completion summary

## Related Skills

- **`cc:analyzing-focus-areas`** - When user specifies a focus area
- **`cc:validating-components`** - Detailed validation criteria by component type

## Additional Resources

- **`references/interactive-patterns.md`** - AskUserQuestion patterns
- **`references/approval-workflows.md`** - Multi-step approval patterns
