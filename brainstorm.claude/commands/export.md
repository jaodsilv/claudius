---
description: Exports or regenerates brainstorming session documents. Use for generating fresh specification from session data.
allowed-tools: Task, Read, Write, Edit, Glob
argument-hint: --session-path: <session_path> --format: <markdown|pdf|html>
---

# Brainstorm Export

Regenerates specification documents from completed brainstorming session.

## Parameters

```yaml
properties:
  session_path:
    type: string
    description: Path to session output directory
    required: true
  format:
    type: string
    enum: [markdown, pdf, html]
    default: markdown
```

Arguments: `<arguments>$ARGUMENTS</arguments>`

## Execution Checklist

### Step 1: Validate Session

- [ ] Check `{{session_path}}` exists
- [ ] Check `{{session_path}}/session-log.md` exists
- [ ] Exit with error if not found

### Step 2: Read Session Data

Read all session files:

- `{{session_path}}/session-log.md`
- `{{session_path}}/requirements.md` (if exists)
- `{{session_path}}/specification.md` (if exists)

Extract: Topic, Depth, Completion status

### Step 3: Regenerate Documents

Launch `brainstorm-specification-writer`:

```text
Regenerate specification from session data.
Session path: {{session_path}}
Output format: {{format}}

Use templates from: brainstorm:brainstorming skill references/
- requirements-document.md
- session-summary.md
```

### Step 4: Generate Format-Specific Outputs

| Format | Files Generated |
|--------|----------------|
| markdown | `specification.md`, `requirements.md`, `summary.md` |
| pdf | Convert markdown to PDF (requires pandoc) |
| html | Convert markdown to HTML with styling |

### Step 5: Report Results

```markdown
## Export Complete

**Session**: {{topic}}
**Format**: {{format}}

### Generated Files
1. `{{session_path}}/specification.md`
2. `{{session_path}}/requirements.md`
3. `{{session_path}}/summary.md`

### Export Notes
[Any notes about the export process]
```

## Usage Examples

```text
/brainstorm:export --session-path: ./brainstorm-output/
/brainstorm:export --session-path: ./brainstorm-output/ --format: html
```
