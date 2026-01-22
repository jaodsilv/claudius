---
description: Bumps plugin versions when PR changes affect plugins. Use for release preparation.
argument-hint: "[--plugins <list>] [--bump-version <x.y.z>] [--marketplace-only | --no-marketplace]"
allowed-tools: []
model: haiku
---

# Bump Plugin Versions

This is a **script-only command** - the hook script handles everything automatically.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--plugins <list>` | Comma-separated plugin names | Auto-detect from changes |
| `--pr <number>` | PR number to analyze for changed files | - |
| `--no-marketplace` | Skip marketplace version bump | - |
| `--marketplace` | Bump marketplace version too | **default** |
| `--marketplace-only` | Only bump marketplace, no plugins | - |
| `--bump-version <x.y.z>` | Version increment (supports `-x.y.z`) | `0.0.1` |
| `--bump-marketplace-version <x.y.z>` | Marketplace increment | Same as `--bump-version` |

## Bump Types

- **Patch** (default): `--bump-version 0.0.1` → `X.Y.Z` becomes `X.Y.(Z+1)`
- **Minor**: `--bump-version 0.1.0` → `X.Y.Z` becomes `X.(Y+1).0`
- **Major**: `--bump-version 1.0.0` → `X.Y.Z` becomes `(X+1).0.0`

## What the Script Does

1. Auto-detects affected plugins from git changes (or uses explicit `--plugins`)
2. Validates all plugins exist in marketplace.json
3. Reads current versions from all files
4. Calculates new versions based on bump increment
5. Updates files in order:
   - Plugin `plugin.json` files
   - `marketplace.json` plugin entries
   - `marketplace.json` root version
   - `package.json` root version
6. Updates metadata at `.thoughts/marketplace/latest-version-bump.yaml`
7. Prints summary table

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - versions bumped, see output for summary |
| 2 | Blocked - nothing to bump, or validation failed |

## Examples

```bash
# Auto-detect and bump patch version (default)
/cc:bump-version

# Bump specific plugins
/cc:bump-version --plugins cc,gitx

# Minor version bump
/cc:bump-version --bump-version 0.1.0

# Only bump marketplace, not individual plugins
/cc:bump-version --marketplace-only

# Bump plugins but not marketplace root version
/cc:bump-version --no-marketplace
```

## Execution

The hook script has completed all version bumps. Check the output above for:

- Files modified with before/after versions
- Detection method used
- Metadata file location

**Next step**: Review changes with `git diff`, then commit and push.
