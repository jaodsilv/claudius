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

Verify session exists and is exportable:

1. Check that `{{session_path}}` exists. Missing directory indicates invalid path.
2. Check that `{{session_path}}/session-log.md` exists. Missing log indicates no session data.
3. If not found, inform user and exit. Early exit prevents confusing errors.

### Step 2: Read Session Data

Gather all session artifacts for regeneration:

1. Read all session files:
   1. `{{session_path}}/session-log.md`. Log contains dialogue insights.
   2. `{{session_path}}/requirements.md` (if exists). Requirements inform specification.
   3. `{{session_path}}/specification.md` (if exists). Existing spec provides baseline.

2. Extract session metadata:
   1. Topic. Topic identifies the session.
   2. Depth. Depth indicates exploration thoroughness.
   3. Completion status. Status determines available content.

### Step 3: Regenerate Documents

Produce fresh specification from session data:

1. Launch `brainstorm-specification-writer` agent using the Task tool with:

   ```text
   Regenerate specification document from session data.

   Session path: {{session_path}}
   Output format: {{format}}

   Read all session outputs and generate a fresh specification document.
   ```

2. Save regenerated document to appropriate format. Format determines file extension and processing.
   1. Markdown: `{{session_path}}/specification.md`
   2. PDF: `{{session_path}}/specification.pdf` (if supported)
   3. HTML: `{{session_path}}/specification.html` (if supported)

### Step 4: Generate Additional Exports

Produce format-specific outputs:

#### Markdown (default)

Default format provides maximum compatibility:

1. Regenerate `specification.md`. Full specification for detailed review.
2. Regenerate `requirements.md`. Requirements-only view for implementation.
3. Create `summary.md` (executive summary only). Summary enables quick stakeholder orientation.

#### PDF (if requested)

PDF provides print-ready output:

1. Convert markdown to PDF using available tools. PDF preserves formatting.
2. Note: May require external tool (pandoc, etc.). External tools extend capabilities.

#### HTML (if requested)

HTML provides browser-viewable output:

1. Convert markdown to HTML. HTML enables web sharing.
2. Apply basic styling for readability. Styling improves reading experience.

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

1. This command can be run multiple times to regenerate documents. Idempotent export enables iterative refinement.
2. Regeneration uses the session log as the source of truth. Log-based regeneration ensures consistency.
3. PDF export requires external tools and may not be available in all environments. Tool availability varies by system.
4. HTML export creates a standalone file with embedded styles. Embedded styles enable offline viewing.
