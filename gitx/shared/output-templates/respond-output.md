# Respond Workflow Output Template

This template defines the structure for output from the respond workflow agents.

## Review Comment Analysis Output

```markdown
## Review Comment Analysis

### Summary
- **Total unresolved comments**: X
- **By category**: code-style (X), logic-error (X), performance (X), security (X), documentation (X), testing (X)
- **By effort**: trivial (X), minor (X), moderate (X), significant (X)

### Comments (Priority Order)

#### Comment 1: [CATEGORY] - [EFFORT]
- **ID**: [thread-id]
- **Author**: @username
- **File**: path/to/file.ts:42-45
- **Comment**: "Original review text..."
- **Context**: Brief description of the code being reviewed
- **Resolution Approach**: Suggested way to address this
- **Dependencies**: None | Depends on Comment X
```

## CI Failure Analysis Output

```markdown
## CI Failure Analysis

### Summary
- **Total failed checks**: X
- **By category**: test-failure (X), lint-error (X), type-error (X), build-failure (X)

### Failures (Priority Order)

#### Check 1: [CHECK_NAME] - [CATEGORY]
- **Status**: failure
- **Details URL**: [link]
- **Root Cause**: Description
- **Affected Files**: [list]
- **Suggested Fix**: Steps
- **Complexity**: trivial | minor | moderate | significant
```

## Execution Plan Output

```markdown
## Execution Plan

### Overview
- **Total changes**: X
- **Estimated time**: X-Y minutes
- **Quality gates**: X

### Phases

#### Phase 1: Foundation
| # | Type | File | Description | Depends On |
|---|------|------|-------------|------------|
| 1 | ... | ... | ... | ... |

[QUALITY GATE]: Description

#### Phase 2: Core Changes
...
```

## Synthesized Action Plan Output

```markdown
## Action Plan

### Summary
| Metric | Value |
|--------|-------|
| Total Issues | X |
| Tier 1 (Critical) | X |
| Tier 2 (Important) | X |
| Tier 3 (Enhancement) | X |

### Tier 1: Critical
[Issues that must be fixed]

### Tier 2: Important
[Issues that should be fixed]

### Tier 3: Enhancement
[Nice to have fixes]

### Conflicting Recommendations
[Any conflicts between analyses]
```
