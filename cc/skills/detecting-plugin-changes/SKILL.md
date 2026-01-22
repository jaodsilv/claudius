---
name: cc:detecting-plugin-changes
description: Detects which plugins are affected by changed files in a PR or git diff. Use when analyzing what plugins need version bumps or when determining scope of changes.
allowed-tools: Bash(scripts/detect-affected-plugins.sh:*)
version: 1.0.0
---

## Overview

This skill provides automated detection of affected plugins based on changed files. It analyzes either a PR's changed files or local git diff to determine which plugins in the marketplace are impacted.

## Usage

### From a PR

```bash
scripts/detect-affected-plugins.sh "123" "."
```

### From Uncommitted/Unpushed Changes

```bash
scripts/detect-affected-plugins.sh "" "."
```

## Input Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `$1` | No | PR number (empty string for git diff mode) |
| `$2` | No | Working directory (defaults to ".") |

## Using the Output

The script returns JSON with these actionable fields:

1. **Detection context**: Use `detectionMethod` ("pr" or "git-diff") and `prNumber` (if applicable) to explain how plugins were identified
2. **Affected plugins**: Iterate `affectedPlugins[]` to process each plugin:
   - `name`: Plugin name from marketplace.json (use for display and version bumping)
   - `source`: Plugin source directory (use for file operations)
   - `files`: Changed files within this plugin (paths relative to plugin root, not repo root)
3. **Metrics**: Use `totalChangedFiles` for reporting summary
4. **Unmatched files**: Check `unmatchedFiles[]` for files that don't belong to any plugin (may indicate new plugins or config files)

### Example Reporting

```text
Detected via {detectionMethod}: {totalChangedFiles} files affecting {affectedPlugins.length} plugin(s):
- {name}: {files.length} file(s) changed
```

## Error Handling

- Exits with code 1 if marketplace.json is not found
- Errors are written to stderr
- Returns empty affectedPlugins array if no plugins match
