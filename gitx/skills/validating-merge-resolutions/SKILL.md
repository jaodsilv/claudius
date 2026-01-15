---

name: gitx:validating-merge-resolutions
description: >-
  Provides validation checklist and patterns for merge/rebase conflict
  resolutions. Use when checking resolved files before continuing git operations.
version: 1.0.0
allowed-tools: Bash(grep:*), Bash(npx:*), Bash(npm:*)
model: haiku
---

# Validating Merge Resolutions

Validation checklist for conflict resolutions before continuing operations.

## Validation Checklist

### 1. Conflict Markers Check

```bash
grep -rn "^<<<<<<< " --include="*.ts" --include="*.tsx" --include="*.js" --include="*.json"
grep -rn "^=======" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.json"
grep -rn "^>>>>>>> " --include="*.ts" --include="*.tsx" --include="*.js" --include="*.json"
```

Any remaining markers = blocking error.

### 2. Syntax Validation

```bash
# TypeScript/JavaScript
npx tsc --noEmit <file>

# JSON
cat <file.json> | jq . > /dev/null
```

### 3. Type Check

```bash
npm run typecheck 2>&1 | head -50
```

### 4. Lint Check

```bash
npm run lint -- <resolved-files> 2>&1 | head -50
```

## Result Format

```markdown
## Validation Report

| Check | Status | Details |
|-------|--------|---------|
| Conflict Markers | Pass/Fail | [count remaining] |
| Syntax Valid | Pass/Fail | [errors found] |
| Types Check | Pass/Fail | [type errors] |
| Lint Check | Pass/Warn | [warnings] |

### Overall: READY TO CONTINUE / ISSUES FOUND
```

## Quality Gate

| Result | Action |
|--------|--------|
| PROCEED | All checks pass, safe to continue |
| PROCEED WITH CAUTION | Minor issues, can continue |
| DO NOT PROCEED | Critical issues must be resolved |
