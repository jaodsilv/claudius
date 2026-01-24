---
description: Bumps plugin versions when PR changes affect plugins. Use for release preparation.
argument-hint: "[--plugins <list>] [--delta <x.y.z>] [--scan] [--commit | --no-commit] [--worktree <path>]"
allowed-tools: []
model: haiku
---

# Bump Plugin Versions

This is a **script-only command** - the hook script handles everything automatically and outputs JSON to block the LLM phase.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--plugins <list>` | Comma-separated plugin names | Auto-detect from changes |
| `--pr <number>` | PR number to analyze for changed files | - |
| `--no-marketplace` | Skip marketplace version bump | - |
| `--marketplace` | Bump marketplace version too | **default** |
| `--marketplace-only` | Only bump marketplace, no plugins | - |
| `--delta <x.y.z>` | Version increment (supports `-x.y.z`) | `0.0.1` |
| `--bump-version <x.y.z>` | *Deprecated alias for --delta* | `0.0.1` |
| `--bump-marketplace-version <x.y.z>` | Marketplace increment | Same as `--delta` |
| `--scan` | Rebuild metadata from git blame, no bumping | - |
| `--commit` | Force commit after version bump | - |
| `--no-commit` | Skip commit even if only version files changed | - |
| `--worktree <path>` | Override worktree path | CWD |

## Modes

### Bump Mode (default)

Detects affected plugins and bumps versions.

### Scan Mode (`--scan`)

Rebuilds the metadata file from git blame without bumping any versions. Useful for initializing or repairing metadata.

## Bump Types

- **Patch** (default): `--delta 0.0.1` → `X.Y.Z` becomes `X.Y.(Z+1)`
- **Minor**: `--delta 0.1.0` → `X.Y.Z` becomes `X.(Y+1).0`
- **Major**: `--delta 1.0.0` → `X.Y.Z` becomes `(X+1).0.0`

## Auto-Commit Behavior

When neither `--commit` nor `--no-commit` is specified:
- If only version files are changed → auto-commits
- If other files are changed → skips commit

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
   - Preserves existing entries for non-bumped plugins
   - Records commit SHA if committing
7. Optionally commits the version bump
8. Outputs JSON blocking response

## Metadata Format

```yaml
# Last version bump metadata
marketplace:
  commit: <sha>
  datetime: "<timestamp>"
  version: <x.y.z>
plugins:
  <plugin-name>:
    commit: <sha>
    datetime: "<timestamp>"
    version: <x.y.z>
  ...
```

## Exit Behavior

| Scenario | Exit Code | Output |
|----------|-----------|--------|
| Success (bump) | 0 | `{"decision": "block", "reason": "Versions bumped: ..."}` |
| Success (scan) | 0 | `{"decision": "block", "reason": "Metadata rebuilt from git blame."}` |
| Nothing to bump | 2 | stderr: "Nothing to bump..." |
| Validation failure | 2 | stderr: error message |

## Examples

```bash
# Auto-detect and bump patch version (default)
/cc:bump-version

# Bump specific plugins
/cc:bump-version --plugins cc,gitx

# Minor version bump
/cc:bump-version --delta 0.1.0

# Only bump marketplace, not individual plugins
/cc:bump-version --marketplace-only

# Bump plugins but not marketplace root version
/cc:bump-version --no-marketplace

# Rebuild metadata from git blame
/cc:bump-version --scan

# Force commit after bump
/cc:bump-version --commit

# Bump in different worktree
/cc:bump-version --worktree /path/to/repo
```

## Execution

The hook script completes all version bumps and outputs JSON to block the LLM phase.
