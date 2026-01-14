# Skill Validation Criteria

Detailed validation rules for Claude Code skills.

## Frontmatter Validation

### Required Fields

| Field | Requirement | Severity if Missing |
|-------|-------------|---------------------|
| name | Format: `namespace:skill-name` | CRITICAL |
| description | Third-person, trigger phrases | CRITICAL |
| version | Semantic version format | HIGH |

## Description Validation

### Writing Style

| Criterion | Good | Bad | Severity |
|-----------|------|-----|----------|
| Perspective | "This skill provides..." | "Use this skill to..." | HIGH |
| Trigger phrases | "Use when implementing..., analyzing..." | Vague descriptions | HIGH |
| Scenarios | Lists concrete use cases | Generic capabilities | MEDIUM |

### Description Examples

Good:

```yaml
description: >-
  Provides progressive disclosure patterns for organizing skill content.
  Use when creating new skills, reorganizing existing skills, or reviewing
  skill structure for best practices.
```

Bad:

```yaml
description: "Helps you organize skill content"  # Second-person, no triggers
```

## Content Validation

### Writing Style

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| Form | Imperative (verb-first) | HIGH |
| Person | No second-person ("you should") | HIGH |
| Structure | Procedural, step-by-step | MEDIUM |

### Length Guidelines

| Component | Target | Severity if Exceeded |
|-----------|--------|----------------------|
| SKILL.md | 1500-2000 words | HIGH (if >5000) |
| Individual references | Unlimited | - |
| Total skill | Consider splitting if >10000 | MEDIUM |

## Progressive Disclosure

### SKILL.md Content

Include in main file:

- Overview and purpose
- Core concepts (essential knowledge)
- Essential procedures (common workflows)
- Quick reference tables
- Pointers to detailed resources

Avoid in main file:

- Exhaustive documentation
- Edge cases and troubleshooting
- Extensive examples
- API reference details

### Reference Files

`references/` directory for:

- Detailed patterns and techniques
- Comprehensive documentation
- Migration guides
- Edge cases and troubleshooting
- Extensive examples

### Other Directories

| Directory | Purpose |
|-----------|---------|
| `examples/` | Complete, runnable code and templates |
| `scripts/` | Validation utilities, automation tools |

## Quality Criteria

### CRITICAL Issues

Must fix immediately:

- Missing SKILL.md
- Invalid frontmatter syntax
- No description field
- Referenced files don't exist

### HIGH Issues

Should fix for quality:

- Description not third-person
- No trigger phrases in description
- Second-person writing style ("you should")
- SKILL.md too long (>5000 words)
- Missing resource references

### MEDIUM Issues

Consider fixing for improvement:

- Description lacks specific scenarios
- Content could be moved to references/
- Missing examples directory
- Incomplete procedure steps

### LOW Issues

Nice to have polish:

- Minor wording improvements
- Format consistency
- Additional examples
- Version number update

## Resource Validation

| Check | Requirement | Severity |
|-------|-------------|----------|
| Referenced files exist | All `references/*.md` mentioned in SKILL.md must exist | CRITICAL |
| No duplication | Content not repeated across files | HIGH |
| Focused files | Each file has single focused purpose | MEDIUM |
| Proper linking | References use relative paths | HIGH |

## Example Structure

```
my-skill/
├── SKILL.md           # Core concepts (1500-2000 words)
├── references/
│   ├── patterns.md    # Detailed patterns
│   ├── examples.md    # Extended examples
│   └── edge-cases.md  # Troubleshooting
├── examples/
│   ├── basic.md       # Simple example
│   └── advanced.md    # Complex example
└── scripts/
    └── validate.sh    # Utility script
```
