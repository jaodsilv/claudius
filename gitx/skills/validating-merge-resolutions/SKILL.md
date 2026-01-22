---
name: gitx:validating-merge-resolutions
description: >-
  Provides validation checklist and patterns for merge/rebase conflict
  resolutions. Use when checking resolved files before continuing git operations.
allowed-tools: Bash(scripts/validate-resolution.sh:*)
model: sonnet
---

# Validating Merge Resolutions

Validation checklist for conflict resolutions before continuing operations.

## Usage

Run the validation script (auto-detects project language):

```bash
scripts/validate-resolution.sh
```

Or specify file patterns explicitly:

```bash
scripts/validate-resolution.sh "*.py" "*.pyi"
```

## Language Detection

The script auto-detects project type by checking for:

| Language | Detection Files | Type Checker | Linter |
|----------|-----------------|--------------|--------|
| Python | pyproject.toml, setup.py, requirements.txt | mypy, pyright | ruff, flake8 |
| TypeScript/JS | tsconfig.json, package.json | tsc | npm lint |
| Go | go.mod | go vet | golangci-lint |
| Rust | Cargo.toml | cargo check | cargo clippy |

## Checks Performed

1. **Conflict Markers** - Scans for `<<<<<<<`, `=======`, `>>>>>>>` markers
2. **Config Syntax** - Validates `.json` and `.yaml`/`.yml` files
3. **Type Check** - Runs language-appropriate type checker if available
4. **Lint Check** - Runs language-appropriate linter if available

## Output

Returns a markdown validation report:

```markdown
## Validation Report

| Check | Status | Details |
|-------|--------|---------|
| Conflict Markers | PASS | 0 remaining |
| Syntax Valid | PASS | OK |
| Types Check | PASS | OK |
| Lint Check | PASS | OK |

### Overall: PROCEED

All checks passed
```

## Status Values

| Status | Meaning |
|--------|---------|
| PASS | Check passed |
| FAIL | Check failed, blocks operation |
| WARN | Warning, can proceed with caution |
| SKIP | No tool available for this check |

## Quality Gate

| Result | Action |
|--------|--------|
| PROCEED | All checks pass, safe to continue |
| PROCEED_WITH_CAUTION | Minor issues, can continue |
| DO_NOT_PROCEED | Critical issues must be resolved |
