# Analysis Schema

## Full Analysis Template

```markdown
# Analysis: [Brief Title]

## Metadata
- **Input Type**: [review-comment|ci-log|error-text|task-description|generic]
- **Analyzed At**: [ISO timestamp]
- **Source**: [Brief description of what was analyzed]
- **Finding Count**: [N]

## Executive Summary

[2-3 sentences describing the overall situation, key findings, and recommended action.]

## Findings

### Finding 1: [Title]
- **Severity**: critical|high|medium|low
- **Effort**: trivial|minor|moderate|significant
- **Root Cause**: [Clear description of why this is happening]
- **Affected Files**:
  - `path/to/file.ext:42` — [what's wrong at this location]
  - `path/to/other.ext:87` — [related issue]
- **Evidence**: [Specific error messages, log lines, or code snippets]
- **Suggested Approach**:
  1. [Step 1]
  2. [Step 2]

### Finding 2: [Title]
[Same structure as above]

## Cross-Cutting Concerns

[Patterns that span multiple findings, shared root causes, or systemic issues]

## Recommended Order

1. [Finding N] — [reason to address first, e.g., "blocks other fixes"]
2. [Finding M] — [reason for this position]
```

## Compact Summary Template

```markdown
# Analysis Summary

**Input**: [type] | **Findings**: [N] | **Critical**: [X] | **High**: [Y]

## Top Findings
1. **[CRITICAL]** [Finding title] — [one-line description]
2. **[HIGH]** [Finding title] — [one-line description]
3. **[MEDIUM]** [Finding title] — [one-line description]

## Assessment
[1-2 sentences: overall health, recommended next step]
```
