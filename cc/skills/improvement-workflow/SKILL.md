---
name: Improvement Workflow
description: >-
  This skill should be used when implementing "interactive improvements",
  "analyze-suggest-approve-apply patterns", "component improvement workflows",
  "user approval workflows", "severity-based suggestions", or designing
  interactive improvement experiences for Claude Code components.
version: 1.0.0
---

# Interactive Improvement Workflow

Patterns for implementing interactive improvement workflows that analyze components, suggest improvements, get user approval, and apply changes.

## Why Use This Pattern

The interactive improvement workflow ensures changes are transparent, reversible, and user-controlled.
Instead of applying improvements silently, this pattern:

1. **Builds trust** - Users see exactly what will change before it happens
2. **Prevents surprises** - Severity-based grouping helps users prioritize
3. **Maintains control** - Users choose which improvements to apply
4. **Documents changes** - Clear before/after tracking for each modification

Use this pattern for any command or agent that modifies existing code or configuration.

## Core Workflow Pattern

The improvement workflow consists of four phases executed sequentially.

### Phase 1: Analysis

Load the target component and apply the appropriate analysis framework.

1. Read the component file(s) completely
2. Apply component-specific analysis criteria
3. Generate structured improvement suggestions
4. Categorize each suggestion by severity level

Analysis output structure:

```markdown
## Analysis Summary

### Component: [name]
### Type: [command|agent|skill|orchestration|plugin]
### Overall Quality: [assessment]

### Suggestions by Severity

#### CRITICAL
1. [Issue]: [Specific fix]

#### HIGH
1. [Issue]: [Specific fix]

#### MEDIUM
1. [Issue]: [Specific fix]

#### LOW
1. [Issue]: [Specific fix]
```

### Phase 2: Presentation

Present analysis results to the user in a clear, actionable format.

1. Show component summary (name, type, location)
2. Display overall quality assessment
3. Group suggestions by severity level
4. Explain the impact of each improvement
5. Use clear, concise language

### Phase 3: Approval

Obtain user approval before making changes using AskUserQuestion.

**Batch Approval Pattern:**

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

**Individual Selection Pattern:**

```text
Question: "Which improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List of specific improvements]
```

### Phase 4: Application

Apply approved changes systematically.

1. For each approved improvement:
   - Show the specific change (before/after if significant)
   - Apply change using Edit tool
   - Confirm successful application
2. Validate final state
3. Present completion summary

## Severity Levels

### CRITICAL

Issues that break functionality or pose security risks.

- Broken syntax or invalid structure
- Missing required fields
- Security vulnerabilities
- Incorrect tool permissions

### HIGH

Significant best practice violations.

- Missing triggering examples (agents)
- Incorrect writing style (skills)
- Overly permissive tool access
- Poor argument handling

### MEDIUM

Enhancement opportunities.

- Incomplete documentation
- Suboptimal organization
- Missing edge case handling
- Redundant code or content

### LOW

Polish and refinement.

- Style consistency
- Minor wording improvements
- Formatting adjustments
- Additional examples

## Component-Specific Analysis

Each component type has specific analysis criteria. Load the appropriate patterns from references:

- **`references/interactive-patterns.md`** - AskUserQuestion patterns and user interaction flows
- **`references/approval-workflows.md`** - Multi-step approval and batch processing patterns

## Progressive Application

For large improvement sets, apply progressively:

1. Address CRITICAL issues first (with confirmation)
2. Address HIGH issues (with selection)
3. Address MEDIUM issues (with selection)
4. Offer LOW issues as optional polish
