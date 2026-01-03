---
name: cc:authoring-skills
description: >-
  Guides skill authoring following Anthropic platform best practices. Use when
  creating new skills, reviewing existing skills, or improving skill structure.
  Covers conciseness, naming, descriptions, progressive disclosure, and validation.
version: 1.0.0
---

# Authoring Skills

Best practices for writing effective Claude Code skills.

## Quick Reference Checklist

Before publishing, verify:

- [ ] Description is third-person with "what + when" triggers
- [ ] SKILL.md body under 500 lines
- [ ] Additional details in separate reference files
- [ ] No time-sensitive information
- [ ] Consistent terminology throughout
- [ ] File references one level deep from SKILL.md
- [ ] Workflows have clear validation steps

## Core Principles

### 1. Conciseness

The context window is a public good. Only add context Claude doesn't already have.

| Ask Yourself | If Yes |
|--------------|--------|
| Does Claude already know this? | Remove it |
| Can I assume Claude knows this? | Remove explanation |
| Does this justify its token cost? | Keep or condense |

**Good** (~50 tokens):

```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

**Bad** (~150 tokens): "PDF files are a common format... There are many libraries..."

### 2. Degrees of Freedom

Match specificity to task fragility:

| Freedom | When to Use | Example |
|---------|-------------|---------|
| High | Multiple valid approaches | Code review guidelines |
| Medium | Preferred pattern with variation | Parameterized scripts |
| Low | Fragile/critical operations | Database migrations |

### 3. Model Testing

Test skills with all target models:

- **Haiku**: Does skill provide enough guidance?
- **Sonnet**: Is skill clear and efficient?
- **Opus**: Does skill avoid over-explaining?

## Naming Conventions

Use **gerund form** (verb + -ing) for skill names:

| Good | Avoid |
|------|-------|
| `processing-pdfs` | `pdf-processor` |
| `analyzing-data` | `data-analysis` |
| `testing-code` | `test-runner` |

**Rules**:

1. Lowercase letters, numbers, hyphens only
2. Maximum 64 characters
3. No reserved words: "anthropic", "claude"
4. No XML tags

## Description Format

Always third-person. Include what + when triggers.

**Pattern**:

```yaml
description: >-
  [What it does]. Use when [triggers].
  [Optional: additional context].
```

**Examples**:

```yaml
# Good
description: >-
  Extracts text and tables from PDF files, fills forms, merges documents.
  Use when working with PDF files or when the user mentions PDFs, forms,
  or document extraction.

# Bad - vague
description: Helps with documents

# Bad - wrong person
description: I can help you process PDFs
```

## Content Guidelines

1. **No time-sensitive info**: Use "old patterns" sections for deprecated content
2. **Consistent terminology**: Pick one term, use it everywhere
3. **Concrete examples**: Show input/output pairs, not abstractions

## Reference Navigation

Read reference files based on your task:

| Task | Reference File |
|------|----------------|
| Organizing skill content | [references/structure.md](references/structure.md) |
| Writing workflow templates | [references/patterns.md](references/patterns.md) |
| Testing and iteration | [references/evaluation.md](references/evaluation.md) |
| Adding scripts/dependencies | [references/advanced.md](references/advanced.md) |
