---
description: Read all plugin.json and the marketplace.json, and fix inconsistencies.
argument-hint: "[--plugins <list>] [--fix]"
allowed-tools: ["Read", "Edit", "AskUserQuestion", "TodoWrite"]
model: sonnet
---

# Sync Plugin Configurations

Detects and resolves inconsistencies between plugin.json files and marketplace.json entries.

## Arguments

- `--plugins <list>`: Comma-separated plugin names to check (default: all plugins)
- `--fix`: Apply fixes automatically without interactive prompts

## Context

The hook script has already analyzed configurations and found inconsistencies.
Check stdout from the hook for the diff summary showing:

- Version mismatches between marketplace.json entries and plugin.json files
- Name mismatches
- Description mismatches
- Missing plugin.json files

## Execution

### Phase 1: Review Detected Differences

Read hook output to understand:

1. Which plugins have inconsistencies
2. What type of inconsistency (version, name, description)
3. The highest version found across all configs

### Phase 2: Resolve Version Differences

For version mismatches:

1. If `--fix` was provided: Apply highest version to all files
2. Otherwise: Ask user which version to use (suggest highest)

```text
AskUserQuestion:
  Question: "Version mismatch detected. Which version should be applied?"
  Options:
  - Use highest: X.Y.Z (Recommended)
  - Keep marketplace version: A.B.C
  - Keep plugin.json version: D.E.F
  - Cancel
```

### Phase 3: Resolve Other Differences

For name/description mismatches:

1. If `--fix` was provided: Use plugin.json value (source of truth)
2. Otherwise: Ask user which value to keep

### Phase 4: Apply Changes

For each file needing updates:

1. Read current content
2. Edit the version/name/description field
3. Verify edit succeeded

Update order:

1. Individual plugin.json files first
2. marketplace.json plugin entries
3. Root marketplace.json version (if updating to highest)

### Phase 5: Summary

```markdown
## Config Sync Complete

| Plugin | Field | Before | After |
|--------|-------|--------|-------|
| cc | version | 1.0.0 | 1.1.0 |
| gitx | version | 1.0.5 | 1.1.0 |
| ... | ... | ... | ... |

Files Modified: [list]
```

## Error Handling

| Error | Action |
|-------|--------|
| Edit failure | Report file, continue with others |
| File not found | Skip plugin, report in summary |
| Invalid JSON | Report parsing error, skip file |
