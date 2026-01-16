---

description: Bumps plugin versions when PR changes affect plugins. Use for release preparation.
argument-hint: "[--pr <number>] [--plugins <list>]"
allowed-tools: ["Bash(gh:*)", "Bash(git:*)", "Read", "Edit", "AskUserQuestion", "TodoWrite"]
---

# Bump Plugin Versions

Updates version fields in package.json, marketplace.json, and plugin.json files.

## Arguments

- `--pr <number>`: PR number to analyze for changed files
- `--plugins <list>`: Comma-separated plugin names (e.g., `cc,gitx`)

## Execution

### Phase 1: Detect Affected Plugins

Track with TodoWrite: Detect plugins, Validate, Get bump type, Read versions, Update files, Summary

**If --plugins provided**: Parse list directly.

**If --plugins NOT provided**:

1. Check for PR (--pr flag or `gh pr view --json number`)
2. If PR found: `gh pr view <number> --json files --jq '.files[].path'`
3. If no PR: Use git diff from main/master
4. Read `.claude-plugin/marketplace.json` to map directories to plugin names
5. Match changed file paths to plugin directories

Report: detection method, file count, affected plugins.

### Phase 2: Validate Plugins

For each plugin:

- [ ] Exists in marketplace.json
- [ ] Has plugin.json at `<source>/.claude-plugin/plugin.json`

If missing, ask: remove and continue, or cancel.

### Phase 3: Get Bump Type

```text
AskUserQuestion:
  Question: "What type of version bump?"
  Options:
  - patch (X.Y.Z+1)
  - minor (X.Y+1.0)
  - major (X+1.0.0)
  - Cancel
```

### Phase 4: Read & Validate Versions

Read from:

1. `./package.json` - root version
2. `./.claude-plugin/marketplace.json` - marketplace and plugin entry versions
3. `<plugin>/.claude-plugin/plugin.json` - individual plugin versions

Validation:

- [ ] Format matches `X.Y.Z` or `X.Y.Z-prerelease`
- [ ] Marketplace and plugin.json versions match (ask if mismatch)
- [ ] Handle pre-release suffixes (confirm stripping)

### Phase 5: Apply Updates

Track `$successful_edits` for rollback. For each file:

1. Edit version string
2. Add to successful edits on success
3. On failure: report error, provide rollback command

### Phase 6: Summary

```markdown
## Version Bump Complete

| File | Before | After |
|------|--------|-------|
| package.json | X.Y.Z | X.Y.Z' |
| ... | ... | ... |

Files Modified: [list]
Next: git diff, commit, push
```

## Error Handling

| Error | Action |
|-------|--------|
| No plugins detected | Suggest --plugins flag |
| Invalid version format | Report file and exit |
| Git/gh command failure | Exit with command error |
| Edit failure | Report, list modified files, provide rollback |
