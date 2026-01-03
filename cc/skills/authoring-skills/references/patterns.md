# Skill Content Patterns

Common patterns for structuring skill instructions.

## Template Pattern

Provide templates for output format. Match strictness to requirements.

### Strict Template (API responses, data formats)

```markdown
## Report structure

ALWAYS use this exact template:

# [Title]

## Executive summary
[One-paragraph overview]

## Key findings
- Finding 1 with data
- Finding 2 with data

## Recommendations
1. Actionable recommendation
```

### Flexible Template (adaptable guidance)

```markdown
## Report structure

Sensible default format - adapt as needed:

# [Title]

## Executive summary
[Overview]

## Key findings
[Adapt sections to your analysis]
```

## Examples Pattern

Show input/output pairs for style guidance:

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware

**Example 2:**
Input: Fixed bug where dates displayed incorrectly
Output:
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently
```

Examples communicate style more clearly than descriptions.

## Conditional Workflow Pattern

Guide Claude through decision points:

```markdown
## Document modification

1. Determine modification type:

   **Creating new content?** → Follow "Creation workflow"
   **Editing existing content?** → Follow "Editing workflow"

2. Creation workflow:
   - Use docx-js library
   - Build document from scratch
   - Export to .docx format

3. Editing workflow:
   - Unpack existing document
   - Modify XML directly
   - Validate after each change
```

For large workflows, push to separate files.

## Workflow Checklist Pattern

For complex multi-step operations, provide copyable checklists:

```markdown
## PDF form filling workflow

Copy this checklist and track progress:

Task Progress:
- [ ] Step 1: Analyze form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)

**Step 1: Analyze the form**
Run: `python scripts/analyze_form.py input.pdf`
...
```

Checklists help both Claude and users track progress.

## Feedback Loop Pattern

For quality-critical tasks, implement validate-fix-repeat:

```markdown
## Content review process

1. Draft content following STYLE_GUIDE.md
2. Review against checklist:
   - Check terminology consistency
   - Verify examples follow standard format
   - Confirm all required sections present
3. If issues found:
   - Note each issue with section reference
   - Revise content
   - Review checklist again
4. Only proceed when all requirements met
```

Validation loops catch errors early.

## Anti-Pattern: Too Many Options

**Bad** (confusing):

```markdown
You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image...
```

**Good** (provide default with escape hatch):

```markdown
Use pdfplumber for text extraction:

import pdfplumber

For scanned PDFs requiring OCR, use pdf2image with pytesseract instead.
```
