# Conflict Resolution Output Template

This template defines the structure for output from the conflict resolution agents.

## Conflict Analysis Output

````markdown
## Conflict Analysis

### Summary
- **Operation**: merge | rebase
- **Total Conflicts**: X files, Y regions
- **Complexity**: simple | moderate | complex

### File: [path/to/file.ts]

#### Conflict 1 (Lines X-Y)

**Type**: Semantic | Syntactic | Structural | Deletion | Adjacent

**Ours (HEAD)**:
```typescript
[code from current branch]
```

- **What changed**: Description
- **Intent**: Purpose
- **Commit**: [hash] - "[message]"

**Theirs ([branch])**:

```typescript
[code from incoming]
```

- **What changed**: Description
- **Intent**: Purpose
- **Commit**: [hash] - "[message]"

**Analysis**: Why they conflict

**Semantic Overlap**: Exclusive | Additive | Dependent | Contradictory

**Recommended Strategy**: Keep ours | Keep theirs | Combine | Rewrite

````

## Resolution Suggestions Output

````markdown
## Resolution Suggestions

### Summary
- **Total Conflicts**: X
- **High Confidence**: X
- **Medium Confidence**: X
- **Low Confidence**: X

### File: [path/to/file.ts]

#### Resolution for Conflict 1

**Confidence**: High | Medium | Low

**Suggested Resolution**:
```typescript
[resolved code]
```

**Reasoning**: Explanation

**Verification**:

```bash
npm run test -- --testPathPattern="affected"
```

````

## Validation Output

````markdown
## Validation Report

### Summary
| Check | Status |
|-------|--------|
| Conflict Markers | ✅ Pass / ❌ Fail |
| Syntax Valid | ✅ Pass / ❌ Fail |
| Types Check | ✅ Pass / ❌ Fail |

### Result: ✅ READY / ❌ ISSUES FOUND

### Next Steps
```bash
git add <files>
git rebase --continue  # or git commit
```

````
