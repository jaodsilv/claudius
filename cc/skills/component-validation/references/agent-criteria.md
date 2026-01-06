# Agent Validation Criteria

Detailed validation rules for Claude Code agents.

## Frontmatter Validation

### Required Fields

| Field | Requirement | Severity if Missing |
|-------|-------------|---------------------|
| name | 3-50 chars, kebab-case, alphanumeric start/end | CRITICAL |
| description | Triggering conditions with 2-4 example blocks | CRITICAL |

### Optional Fields

| Field | Best Practice | Severity if Violated |
|-------|---------------|----------------------|
| model | Appropriate for task complexity | MEDIUM |
| color | Consistent with agent purpose | LOW |
| tools | Minimal necessary set | HIGH |

## Identifier Validation

| Criterion | Requirement | Examples |
|-----------|-------------|----------|
| Length | 3-50 characters | `code-reviewer`, `pr-analyzer` |
| Characters | Lowercase, numbers, hyphens only | NOT: `Code_Reviewer`, `PR.Analyzer` |
| Format | Starts and ends with alphanumeric | NOT: `-reviewer`, `reviewer-` |
| Descriptive | Clearly indicates function | NOT: `agent1`, `helper` |

## Description Validation

### Triggering Conditions

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| Clarity | Specific, unambiguous conditions | HIGH |
| Example count | 2-4 example blocks | HIGH |
| Example format | context/user/assistant/commentary | HIGH |
| Proactive | Covers proactive triggering if appropriate | MEDIUM |
| Reactive | Covers user request scenarios | HIGH |

### Example Block Format

```markdown
<example>
Context: [Describe the situation]
user: "[What the user says]"
assistant: "[How to respond and invoke agent]"
<commentary>
[Why this triggers the agent]
</commentary>
</example>
```

## System Prompt Validation

### Structure

| Section | Requirement | Severity if Missing |
|---------|-------------|---------------------|
| Role definition | Clear expert persona | HIGH |
| Responsibilities | Numbered, specific list | HIGH |
| Process | Step-by-step workflow | HIGH |
| Quality standards | Defined criteria | MEDIUM |
| Output format | Specified structure | HIGH |
| Edge cases | Addressed appropriately | MEDIUM |

### Length Guidelines

| Length | Assessment | Severity |
|--------|------------|----------|
| <200 words | Too short, lacks guidance | CRITICAL |
| 200-500 words | Minimal, may miss edge cases | MEDIUM |
| 500-3000 words | Ideal range | - |
| >3000 words | May consume excessive context | MEDIUM |

## Quality Criteria

### CRITICAL Issues

Must fix immediately:

- Invalid identifier format (prevents loading)
- Missing or broken examples
- System prompt too short (<200 words)
- Missing role definition

### HIGH Issues

Should fix for quality:

- Insufficient example blocks (<2)
- Vague triggering conditions
- Overly permissive tool access
- Missing process steps
- No output format specified

### MEDIUM Issues

Consider fixing for improvement:

- Examples lack commentary
- Missing edge case handling
- Suboptimal color choice
- Incomplete responsibility list

### LOW Issues

Nice to have polish:

- Example wording improvements
- Additional triggering scenarios
- Format consistency
- Minor prompt refinements

## Model Selection Guidelines

| Task Type | Recommended Model |
|-----------|-------------------|
| Simple analysis, formatting | haiku |
| Standard analysis, design | sonnet |
| Complex reasoning, architecture | opus |

## Color Guidelines

| Purpose | Recommended Color |
|---------|-------------------|
| Analysis, review | blue, cyan |
| Generation, creation | green |
| Validation, caution | yellow |
| Security, critical | red |
| Creative, transformation | magenta |
