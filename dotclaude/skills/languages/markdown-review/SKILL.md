# Markdown Review Skill

This skill provides comprehensive markdown document review capabilities for Claude Code.

## Formatting Checks

### Heading Hierarchy

Headings must follow sequential hierarchy without skipping levels.

❌ **Bad**:

```markdown
# Title
### Skipped H2
```

✅ **Good**:

```markdown
# Title
## Section
### Subsection
```

### List Formatting

Use consistent bullet markers throughout the document.

❌ **Bad**:

```markdown
- Item 1
* Item 2
+ Item 3
```

✅ **Good**:

```markdown
1. First item
2. Second item
3. Third item
```

### Code Blocks

Always specify language for syntax highlighting.

❌ **Bad**: ` ```\ncode here\n``` `

✅ **Good**: ` ```javascript\ncode here\n``` `

### Tables

Align columns consistently for readability.

❌ **Bad**: `| Name|Age |\n|---|---|\n| John | 25|`

✅ **Good**:

```markdown
| Name | Age |
|------|-----|
| John | 25  |
```

### Line Length

Keep lines under 120 characters for better readability in diffs and editors.

## Link Validation

### Internal Links

Verify all relative file paths exist in the repository.

```markdown
[See docs](./docs/README.md) <!-- Must exist -->
```

### Anchor Links

Ensure heading anchors exist in target documents.

```markdown
[Jump](#section-name) <!-- Heading "Section Name" must exist -->
```

### External Links

Check HTTP status codes where possible (should return 200 OK).

```markdown
[Claude](https://claude.ai) <!-- Should be accessible -->
```

### Image Links

Verify image files exist and have descriptive alt text.

❌ **Bad**: `![](image.png)`

✅ **Good**: `![Screenshot of dashboard](./images/dashboard.png)`

## Content Quality

### Trailing Whitespace

Remove trailing spaces and tabs from all lines.

### Consistent Emphasis

Use either `**bold**` or `__bold__` consistently, not both.

❌ **Bad**: `**bold** and __also bold__`

✅ **Good**: `**bold** and **more bold**`

### Special Characters

Escape special markdown characters when used literally.

```markdown
Use \* for literal asterisks, not emphasis
```

### Front Matter Validation

Ensure YAML front matter is valid and properly formatted.

```yaml
---
title: Document Title
date: 2025-10-23
tags: [markdown, review]
---
```

## Structure Checks

### Single H1 Per Document

Each markdown file should have exactly one level-1 heading.

❌ **Bad**: Multiple `# Headings`

✅ **Good**: One `# Title`, followed by `##` sections

### Logical Heading Flow

Headings should create a logical document outline.

### Table of Contents

Documents over 200 lines should include a table of contents.

### README Specifics

README files should include: title, description, installation, usage, license.

## Common Issues

### Bare URLs

Wrap URLs in angle brackets or proper link syntax.

❌ **Bad**: `https://example.com`

✅ **Good**: `<https://example.com>` or `[Example](https://example.com)`

### HTML Instead of Markdown

Prefer markdown syntax over raw HTML.

❌ **Bad**: `<b>bold</b>`

✅ **Good**: `**bold**`

### Inconsistent Formatting

Maintain consistent formatting patterns throughout.

### Dead Links

Check for broken internal and external links regularly.

## Review Output Format

When reviewing markdown files, structure findings as follows:

```markdown
## Markdown Review Results

### File: [filename]

#### Critical Issues
1. [Issue with line number and description]

#### Warnings
1. [Warning with suggestion]

#### Suggestions
1. [Improvement recommendation]

#### Summary
- Total issues: X
- Files reviewed: Y
- Overall quality: [Excellent/Good/Needs Improvement]
```

## Context Variables

This skill expects the following context variables:

1. **`files`**: Array of markdown file paths to review (e.g., `["README.md", "docs/guide.md"]`)
2. **`pr_number`**: Optional PR number for context (e.g., `123`)
3. **`focus`**: Review focus area (e.g., `"formatting"`, `"links"`, `"all"`)

Example usage:

```markdown
Review markdown files: README.md, CONTRIBUTING.md
Focus: formatting and links
PR: #456
```
