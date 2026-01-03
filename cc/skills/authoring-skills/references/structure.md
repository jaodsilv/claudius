# Skill Structure Patterns

Guidelines for organizing skill content with progressive disclosure.

## Progressive Disclosure Patterns

### Pattern 1: High-Level Guide with References

Keep SKILL.md as an overview pointing to detailed materials:

```markdown
# PDF Processing

## Quick start
[Code example]

## Advanced features
**Form filling**: See [FORMS.md](FORMS.md)
**API reference**: See [REFERENCE.md](REFERENCE.md)
```

Claude loads reference files only when needed.

### Pattern 2: Domain-Specific Organization

For skills with multiple domains, organize by domain:

```text
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing)
    ├── sales.md (opportunities, pipeline)
    └── product.md (API usage, features)
```

User asks about sales → Claude reads only `sales.md`.

### Pattern 3: Conditional Details

Show basic content, link to advanced:

```markdown
## Creating documents
Use docx-js for new documents.

## Editing documents
For simple edits, modify XML directly.
**For tracked changes**: See [REDLINING.md](REDLINING.md)
```

## Reference Depth

Keep references **one level deep** from SKILL.md.

**Bad** (too deep):

```text
SKILL.md → advanced.md → details.md → actual info
```

Claude may partially read nested files, missing information.

**Good** (one level):

```text
SKILL.md
├── advanced.md (full content)
├── reference.md (full content)
└── examples.md (full content)
```

## Long File Structure

For files over 100 lines, include a table of contents:

```markdown
# API Reference

## Contents
1. Authentication and setup
2. Core methods (create, read, update, delete)
3. Advanced features (batch operations, webhooks)
4. Error handling patterns

## Authentication and setup
...
```

Claude can see full scope even when previewing.

## Directory Organization

Standard layout:

```text
skills/
  skill-name/
    SKILL.md           # Core content (<300 lines ideal)
    references/        # Optional detailed materials
      examples.md
      patterns.md
    scripts/           # Optional utility scripts
      validate.py
      process.py
```

## Size Guidelines

| Content Type | Target Lines |
|--------------|--------------|
| SKILL.md body | <500 (hard limit) |
| SKILL.md optimal | <300 |
| Reference files | No limit, but use TOC if >100 |
