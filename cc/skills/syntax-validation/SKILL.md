---
name: cc:syntax-validation
description: >-
  Provides syntax validation patterns for Claude Code plugin components. Use
  when validating YAML frontmatter, markdown structure, or component-specific
  syntax after writing or editing files.
version: 1.0.0
---

# Syntax Validation

Patterns for validating plugin component syntax after modifications.

## Validation Checklist

### YAML Frontmatter

1. **Starts correctly**: First line is exactly `---`
2. **Ends correctly**: Closing `---` present
3. **Valid YAML**: No tabs (use spaces), proper indentation
4. **No syntax errors**: Keys and values properly formatted

Common issues:

- Tab characters instead of spaces
- Missing quotes around values with special characters
- Improper list formatting

### Markdown Structure

1. **Heading hierarchy**: H1 → H2 → H3 (no skipping levels)
2. **Code blocks closed**: Every ` ``` ` has a matching closing
3. **Lists formatted**: Consistent bullet/number style, proper nesting
4. **No orphan content**: All content under appropriate headings

### Component-Specific Checks

| Component | Required Fields | Key Validations |
|-----------|-----------------|-----------------|
| Command | description | Under 60 chars, allowed-tools valid |
| Agent | name, description | Kebab-case name, 2+ examples |
| Skill | name, description, version | Third-person description |
| Output-Style | name, description | Formatting rules present |

## Validation Process

After each edit:

1. **Re-read file** to get current state
2. **Parse frontmatter** and check YAML validity
3. **Check structure** for markdown issues
4. **Component validation** based on type
5. **Report issues** with specific line numbers

## Error Patterns

### Invalid Frontmatter

```yaml
# Wrong - tabs used
---
name:\tmy-agent  # TAB character!
---

# Correct - spaces used
---
name: my-agent
---
```

### Unclosed Code Blocks

```markdown
# Wrong
```python
def foo():
    pass
# Missing closing ```

# Correct
```python
def foo():
    pass
```  # Properly closed
```

### Heading Skip

```markdown
# Wrong - skips from H1 to H3
# Main Title

### Subsection  # Should be H2 first!

# Correct
# Main Title

## Section

### Subsection
```

## Integration

Load this skill when applying changes:

```text
Use Skill tool to load cc:syntax-validation
```

Apply validation after each modification and before proceeding to next change.
