# Fix-Issue Workflow Output Template

This template defines the structure for output from the fix-issue workflow agents.

## Issue Analysis Output

```markdown
## Issue Analysis: #[number]

### Overview
- **Title**: [title]
- **Type**: bug | feature | enhancement | refactor | docs | chore
- **Author**: @[username]
- **Labels**: [label1], [label2]

### Summary
[2-3 sentence summary]

### Requirements

#### Explicit Requirements
1. [Requirement from issue]
2. [Another requirement]

#### Implicit Requirements
1. [Inferred requirement] - *Reason*

#### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Complexity Assessment
- **Estimated Size**: [XS | S | M | L | XL]
- **Files to modify**: ~X
- **Risk Factors**: [list]

### Key Terms for Code Search
- `term1`
- `term2`
```text

## Codebase Navigation Output

```markdown
## Codebase Navigation

### Primary Files to Modify
| File | Purpose | Change Type |
|------|---------|-------------|
| src/file.ts | Description | Modify |

### Patterns to Follow
#### Pattern 1: [Name]
- **Example**: src/existing.ts:42-87
- **Why**: Reason

### Test Files
| Implementation | Test File |
|---------------|-----------|
| src/feature.ts | tests/feature.test.ts |

### Impact Assessment
- **Direct Impact**: [files]
- **Potential Impact**: [files]
```text

## Implementation Plan Output

```markdown
## Implementation Plan

### Summary
- **Complexity**: [XS-XL]
- **Phases**: X
- **Checkpoints**: X

### Phase 1: [Name]
**Goal**: Description

#### Step 1.1
- **File**: path/to/file.ts
- **Action**: Description
- **Verification**: Command

[CHECKPOINT]: Description
[COMMIT POINT]: "commit message"

### Phase 2: [Name]
...

### Verification Checklist
- [ ] All criteria met
- [ ] Tests passing
- [ ] No errors
```text
