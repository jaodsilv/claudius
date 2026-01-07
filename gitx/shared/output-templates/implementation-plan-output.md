# Implementation Plan Output Template

Standard format for implementation plans produced by gitx:fix-issue:implementation-planner.

## Full Template

````markdown
## Implementation Plan: Issue #[number]

### Summary
- **Issue**: [title]
- **Complexity**: [XS-XL]
- **Estimated Phases**: X
- **Key Decisions**: [Any decisions made during planning]

### Prerequisites

Before starting:
- [ ] Worktree created on branch: [branch-name]
- [ ] Dependencies installed
- [ ] Development environment ready
- [ ] Issue requirements understood

### Phase 1: Foundation [Est: X min]

**Goal**: [What this phase accomplishes]

#### Step 1.1: [Action]
**File**: `src/types/feature.ts` (create new)
**Action**: Add type definitions

```typescript
// Types to add:
interface FeatureConfig {
  // ...
}
```

**Verification**: `npm run typecheck` passes

#### Step 1.2: [Action]

**File**: `src/config/index.ts` (modify)
**Action**: Add configuration entry
**Lines**: After line 42

```typescript
// Add this:
export const featureConfig = {
  // ...
};
```

**Verification**: Import works in other files

**[CHECKPOINT 1]**: Types compile, config loads
**[COMMIT POINT]**: "feat(types): add feature type definitions"

### Phase 2: Core Implementation [Est: X min]

**Goal**: [What this phase accomplishes]

#### Step 2.1: [Action]

**File**: `src/feature/handler.ts` (create new)
**Action**: Implement main handler
**Pattern**: Follow `src/existing/similar.ts`

```typescript
// Implementation skeleton:
export async function handleFeature(input: FeatureInput): Promise<FeatureOutput> {
  // 1. Validate input
  // 2. Process data
  // 3. Return result
}
```

**Verification**: Unit tests pass

**[CHECKPOINT 2]**: Core functionality works
**[COMMIT POINT]**: "feat(feature): implement core handler"

### Phase 3: Integration [Est: X min]

**Goal**: [What this phase accomplishes]

#### Step 3.1: [Action]

**File**: `src/api/routes.ts` (modify)
**Action**: Add API endpoint
**Lines**: After line 87

```typescript
// Add route:
router.post('/feature', featureHandler);
```

**Verification**: API responds correctly

**[CHECKPOINT 3]**: End-to-end works
**[COMMIT POINT]**: "feat(api): expose feature endpoint"

### Phase 4: Testing [Est: X min]

**Goal**: [Comprehensive test coverage]

#### Step 4.1: Unit Tests

**File**: `tests/feature/handler.test.ts` (create new)
**Tests to write**:
- [ ] Happy path: valid input returns expected output
- [ ] Edge case: empty input handled
- [ ] Error case: invalid input throws
- [ ] Boundary: max limits respected

#### Step 4.2: Integration Tests

**File**: `tests/integration/feature.test.ts` (create new)
**Tests to write**:
- [ ] API endpoint returns 200 on success
- [ ] API endpoint returns 400 on bad input
- [ ] API endpoint returns 500 on internal error

**[CHECKPOINT 4]**: All tests pass
**[COMMIT POINT]**: "test(feature): add comprehensive tests"

### Phase 5: Polish [Est: X min]

**Goal**: [Production readiness]

#### Step 5.1: Error Handling

- Add try-catch blocks
- Add meaningful error messages
- Add logging

#### Step 5.2: Documentation

- Add JSDoc comments
- Update README if needed
- Add inline comments for complex logic

**[CHECKPOINT 5]**: Ready for review
**[COMMIT POINT]**: "docs(feature): add documentation"

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Medium | High | [Strategy] |
| [Risk 2] | Low | Medium | [Strategy] |

### Verification Checklist

Before marking complete:
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] No TypeScript errors
- [ ] No lint warnings
- [ ] Documentation complete
- [ ] Manual testing done

### Commands Reference

```bash
# Development
npm run dev           # Start development server
npm run typecheck     # Check types

# Testing
npm run test          # Run all tests
npm run test:watch    # Watch mode
npm run test -- path/to/test.ts  # Single file

# Quality
npm run lint          # Check lint
npm run lint:fix      # Fix lint issues
```
````
