## Codebase Navigation: [Issue #XXX]

### Architecture Overview

[Brief description of how the relevant parts of the codebase fit together]

### Primary Files to Modify

| File | Purpose | Change Type |
|------|---------|-------------|
| src/components/Feature.tsx | Main UI component | Modify |
| src/api/feature.ts | API integration | Modify |
| src/types/feature.ts | Type definitions | Add new types |

### File Details

#### src/components/Feature.tsx

- **Purpose**: [What this file does]
- **Key Functions**:
  - `functionA()` (line 42) - [What it does]
  - `functionB()` (line 87) - [What it does]
- **Change Needed**: [Specific change description]
- **Related Files**: [Files that interact with this one]

#### src/api/feature.ts

...

### New Files Needed

| Path | Purpose | Based On |
|------|---------|----------|
| src/components/NewFeature.tsx | New feature component | src/components/ExistingFeature.tsx |

### Patterns to Follow

#### Pattern 1: [Pattern Name]

- **Example File**: src/existing/example.ts
- **Key Lines**: 42-87
- **Why Follow**: [Explanation]

```typescript
// Example code snippet showing the pattern
```

#### Pattern 2: [Pattern Name]

...

### Test Files

| Implementation | Test File | Test Type |
|---------------|-----------|-----------|
| src/feature.ts | tests/feature.test.ts | Unit |
| src/api/feature.ts | tests/api/feature.integration.test.ts | Integration |

### Test Patterns to Follow

- Mocking: Use `jest.mock()` as seen in tests/example.test.ts
- Fixtures: See tests/fixtures/ for data patterns
- Assertions: Use `expect().toMatchSnapshot()` for complex objects

### Impact Assessment

#### Direct Impact

Files that will definitely need changes:

- [File 1]
- [File 2]

#### Potential Impact

Files that might need updates:

- [File 3] - If [condition]
- [File 4] - For [edge case]

#### No Impact (Verified)

Areas that seem related but don't need changes:

- [File 5] - Because [reason]

### Code Ownership

| Area | Primary Contributor | Recent Activity |
|------|---------------------|-----------------|
| src/feature/ | @developer | Active (3 commits this week) |
| src/api/ | @other-dev | Stable (no changes in month) |

### Recommendations

1. **Start with**: [File to change first]
2. **Pattern to follow**: [Specific example]
3. **Watch out for**: [Potential gotcha]
4. **Ask about**: [Uncertainty needing clarification]
