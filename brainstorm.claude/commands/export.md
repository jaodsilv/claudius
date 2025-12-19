---
description: Export or regenerate brainstorming session documents
allowed-tools: Task, Read, Write, Edit, Glob
argument-hint: --session-path: <session_path> --format: <markdown|pdf|html>
---

# Brainstorm Export

Export or regenerate specification documents from a completed brainstorming session.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments and extract:

1. `$session_path`: Path to the session output directory (required)
2. `$format`: Output format (default: markdown)

## Parameters Schema

```yaml
brainstorm-export-arguments:
  type: object
  description: Arguments for /brainstorm:export command
  properties:
    session_path:
      type: string
      description: Path to the session output directory
    format:
      type: string
      enum:
        - markdown
        - pdf
        - html
      description: Output format for the specification document
  required:
    - session_path
```

## Default Parameters Values

```yaml
arguments-defaults:
  format: markdown
```

## Execution Workflow

### Step 1: Validate Session

1. Check that `{{session_path}}` exists
2. Check that `{{session_path}}/session-log.md` exists
3. If not found, inform user and exit

### Step 2: Read Session Data

1. Read all session files:
   1. `{{session_path}}/session-log.md`
   2. `{{session_path}}/requirements.md` (if exists)
   3. `{{session_path}}/specification.md` (if exists)

2. Extract session metadata:
   1. Topic
   2. Depth
   3. Completion status

### Step 3: Regenerate Documents

1. Launch `brainstorm-specification-writer` agent using the Task tool with:

   ```text
   Regenerate specification document from session data.

   Session path: {{session_path}}
   Output format: {{format}}

   Read all session outputs and generate a fresh specification document.
   ```

2. Save regenerated document to:
   1. Markdown: `{{session_path}}/specification.md`
   2. PDF: `{{session_path}}/specification.pdf` (if supported)
   3. HTML: `{{session_path}}/specification.html` (if supported)

### Step 4: Generate Additional Exports

Based on format:

#### Markdown (default)

1. Regenerate `specification.md`
2. Regenerate `requirements.md`
3. Create `summary.md` (executive summary only)

#### PDF (if requested)

1. Convert markdown to PDF using available tools
2. Note: May require external tool (pandoc, etc.)

#### HTML (if requested)

1. Convert markdown to HTML
2. Apply basic styling for readability

### Step 5: Report Results

```markdown
## Export Complete

**Session**: {{topic}}
**Format**: {{format}}

### Generated Files

1. `{{session_path}}/specification.md` - Full specification
2. `{{session_path}}/requirements.md` - Requirements only
3. `{{session_path}}/summary.md` - Executive summary

### Export Notes

[Any notes about the export process]
```

## Usage Examples

### Basic Export (Markdown)

```text
/brainstorm:export --session-path: ./brainstorm-output/
```

### Export to HTML

```text
/brainstorm:export --session-path: ./brainstorm-output/ --format: html
```

## Notes

1. This command can be run multiple times to regenerate documents
2. Regeneration uses the session log as the source of truth
3. PDF export requires external tools and may not be available in all environments
4. HTML export creates a standalone file with embedded styles
