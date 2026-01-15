---
name: cc:focus-driven-analysis
description: >-
  Provides focus-driven analysis patterns when the user specifies a priority area
  for review. Use when implementing analysis that should emphasize specific aspects
  while still covering others, such as "focus on error handling" or "prioritize
  triggering issues".
version: 1.0.0
---

# Focus-Driven Analysis

Pattern for prioritizing specific aspects during component analysis while maintaining comprehensive coverage.

## When to Apply

Apply focus-driven analysis when:

1. User specifies a focus area explicitly (e.g., "focus on error handling")
2. Analysis request includes `--focus "..."` argument
3. Context suggests one aspect is more important than others

## Core Pattern

When a focus area is specified:

1. **Prioritize the focus area**: Analyze that aspect first and most thoroughly
2. **Deeper coverage**: Provide more detailed suggestions for focus-related issues
3. **Still mention others**: Note other issues found, but with less detail
4. **Weight appropriately**: Consider focus-related issues as higher priority
5. **Relevant recommendations**: Lead with focus-area recommendations

## Focus Areas by Component Type

### Commands

| Focus Area | Analysis Emphasis |
|------------|-------------------|
| error handling | Error paths, validation, recovery, graceful failures |
| argument handling | Parsing, validation, documentation, $ARGUMENTS usage |
| tool permissions | allowed-tools, least privilege, security |
| writing style | FOR Claude vs TO user, imperative form |
| integration | Agent/skill/file references, Task tool usage |

### Agents

| Focus Area | Analysis Emphasis |
|------------|-------------------|
| triggering | Description, examples, trigger phrases |
| system prompt | Clarity, structure, completeness, length |
| tools | Tool selection, permissions, least privilege |
| examples | Quality, format, context/user/assistant/commentary |
| responsibilities | Role definition, scope boundaries |

### Skills

| Focus Area | Analysis Emphasis |
|------------|-------------------|
| progressive disclosure | Content organization, SKILL.md vs references |
| trigger phrases | Description wording, activation scenarios |
| writing style | Third-person description, imperative body |
| word count | SKILL.md length, content distribution |
| references | Reference file organization, linking |

### Orchestrations

| Focus Area | Analysis Emphasis |
|------------|-------------------|
| phases | Phase structure, transitions, gates |
| data flow | Information passing between phases |
| error handling | Recovery, fallbacks, partial completion |
| coordination | Agent communication, handoffs |
| context management | Context preservation, fresh context usage |

### Output-Styles

| Focus Area | Analysis Emphasis |
|------------|-------------------|
| formatting | Format rules, consistency, examples |
| tone | Voice, formality, audience adaptation |
| structure | Section organization, templates |
| constraints | Length limits, prohibited patterns |

## Output Adaptation

When focus is specified, adapt output:

```markdown
## Analysis Summary

### Focus Area: [specified focus]

[Detailed analysis of focus area - 2-3x normal depth]

### Other Findings

[Brief notes on non-focus issues - condensed]

### Recommendations

1. [Focus-related recommendation]
2. [Focus-related recommendation]
3. [Other recommendation if critical]
```

## Severity Weighting

When focus is specified, adjust severity weighting:

| Issue Type | Normal Weight | With Focus |
|------------|---------------|------------|
| Focus-area CRITICAL | CRITICAL | CRITICAL |
| Focus-area HIGH | HIGH | HIGH |
| Focus-area MEDIUM | MEDIUM | HIGH |
| Focus-area LOW | LOW | MEDIUM |
| Non-focus CRITICAL | CRITICAL | CRITICAL |
| Non-focus HIGH | HIGH | MEDIUM |
| Non-focus MEDIUM | MEDIUM | LOW |
| Non-focus LOW | LOW | (omit) |

## Integration

Load this skill when implementing component analyzers:

```text
Use Skill tool to load cc:focus-driven-analysis
```

Then check if focus area is specified in the request and apply the pattern accordingly.
