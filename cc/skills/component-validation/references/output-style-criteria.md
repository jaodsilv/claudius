# Output-Style Validation Criteria

Detailed validation rules for Claude Code output-styles.

## Frontmatter Validation

### Required Fields

| Field | Requirement | Severity if Missing |
|-------|-------------|---------------------|
| name | Descriptive identifier | CRITICAL |
| description | Clear purpose statement | CRITICAL |

### Optional Fields

| Field | Best Practice | Severity if Violated |
|-------|---------------|----------------------|
| version | Semantic version format | LOW |

## Content Validation

### Required Sections

| Section | Purpose | Severity if Missing |
|---------|---------|---------------------|
| Purpose/Overview | Why this style exists | HIGH |
| Formatting Rules | Specific format requirements | CRITICAL |
| Tone Guidelines | Communication style | HIGH |
| Examples | Before/after or template examples | HIGH |

## Formatting Rules Validation

### Structure

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| Explicit rules | Clear, specific directives | HIGH |
| Examples | Show correct formatting | HIGH |
| Prohibited patterns | What to avoid | MEDIUM |

### Common Rule Categories

| Category | Examples |
|----------|----------|
| Headers | H1 usage, capitalization |
| Lists | Bullet vs numbered, nesting |
| Code blocks | Language tags, line length |
| Tables | When to use, column formatting |
| Links | Inline vs reference style |
| Emphasis | Bold vs italic usage |

## Tone Guidelines Validation

### Required Elements

| Element | Requirement | Severity |
|---------|-------------|----------|
| Voice definition | Active/passive, perspective | HIGH |
| Formality level | Casual, professional, technical | HIGH |
| Audience awareness | Who the output is for | MEDIUM |
| Emotion/neutrality | Emotional tone guidance | MEDIUM |

### Example Tone Specifications

Good:

## Tone

- Use active voice ("The function returns..." not "The value is returned...")
- Professional but approachable
- Avoid jargon unless technical audience confirmed
- Direct and concise, avoid hedging

```text

Bad:
```markdown
## Tone

Be nice and professional.  # Too vague
```

## Example Quality Validation

### Requirements

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| Presence | At least 2 examples | HIGH |
| Clarity | Easy to understand | MEDIUM |
| Relevance | Match intended use cases | HIGH |
| Before/After | Show transformation when applicable | MEDIUM |

### Example Formats

Template example:

## Example: API Documentation

### Input

[Raw API spec]

### Output

[Formatted documentation following this style]

```text

Before/After example:

```markdown
## Example: Commit Message

### Before (incorrect)
fixed bug

### After (correct)
fix(auth): resolve session timeout on inactive tabs
```

## Quality Criteria

### CRITICAL Issues

Must fix immediately:

- Missing formatting rules section
- No examples provided
- Contradictory rules
- Invalid frontmatter

### HIGH Issues

Should fix for quality:

- Vague or incomplete rules
- Missing tone guidelines
- Examples don't match rules
- Unclear purpose statement
- Less than 2 examples

### MEDIUM Issues

Consider fixing for improvement:

- Missing prohibited patterns
- Examples lack variety
- No audience specification
- Incomplete rule coverage

### LOW Issues

Nice to have polish:

- Additional examples
- More specific edge cases
- Format consistency
- Version number

## Consistency Validation

### Internal Consistency

| Check | Description | Severity |
|-------|-------------|----------|
| Rules match examples | Examples follow stated rules | CRITICAL |
| No contradictions | Rules don't conflict | CRITICAL |
| Complete coverage | Major format aspects addressed | HIGH |

### External Consistency

| Check | Description | Severity |
|-------|-------------|----------|
| Plugin consistency | Matches other plugin output-styles | LOW |
| Standard compliance | Follows markdown/format standards | MEDIUM |

## Usage Context

### When Output-Styles Apply

| Context | Application |
|---------|-------------|
| User-facing output | Primary use case |
| Documentation generation | If creating docs |
| Report formatting | If creating reports |
| Internal logs | Usually not needed |

### Loading Output-Styles

Run

```text
/output-style [style-name]
```
