---
description: Bump plugin versions based on PR changes or explicit list
argument-hint: "[--pr <number>] [--plugins <list>]"
allowed-tools: Bash(gh:*), Bash(git:*), Read, Edit, AskUserQuestion, TodoWrite
---

# Bump Plugin Versions

Bump versions for plugins affected by changes in a PR or worktree. Updates package.json (root), marketplace.json (root and plugin entries), and individual plugin.json files.

## Parse Arguments

From $ARGUMENTS, extract:

1. `--pr <number>`: Optional PR number to analyze for changed files
2. `--plugins <list>`: Optional comma-separated list of plugins to bump (e.g., `cc,gitx`)

## Initialize Progress Tracking

```text
TodoWrite:
1. [ ] Detect affected plugins
2. [ ] Validate plugin existence
3. [ ] Get bump type from user
4. [ ] Read current versions
5. [ ] Calculate new versions
6. [ ] Update version files
7. [ ] Present summary
```

## Phase 1: Detect Affected Plugins

Mark "Detect affected plugins" as in_progress.

### If --plugins provided

Parse the comma-separated list into `$affected_plugins` array. Skip to Phase 2.

### If --plugins NOT provided

**Step 1: Determine source of changed files**

If `--pr` provided:

```bash
gh pr view <pr-number> --json files --jq '.files[].path'
```

If `--pr` NOT provided:

1. Check if current worktree has associated PR:

   ```bash
   gh pr view --json number 2>/dev/null
   ```

2. If PR exists: Get its number and fetch files as above
3. If no PR: Get uncommitted/unpushed changes:

   ```bash
   git diff main...HEAD --name-only
   ```

**Step 2: Build plugin-to-directory mapping**

Read `.claude-plugin/marketplace.json` and extract each plugin's `source` field to build a mapping:

```text
For each plugin in $.plugins:
  - Extract name: $.name
  - Extract source: $.source (e.g., "./cc", "./brainstorm.claude")
  - Normalize source: Remove leading "./" if present
  - Store mapping: directory_prefix -> plugin_name
```

**Step 3: Map changed files to plugins**

For each changed file path:

1. Check if path starts with any known plugin directory prefix
2. If match found, add that plugin to `$affected_plugins` (deduplicated)

Mark "Detect affected plugins" as completed.

## Phase 2: Validate Plugin Existence

Mark "Validate plugin existence" as in_progress.

For each plugin in `$affected_plugins`:

1. Verify plugin exists in marketplace.json (has entry in `$.plugins` array)
2. Get the source path from marketplace.json
3. Verify plugin.json exists at: `<source>/.claude-plugin/plugin.json`

If any plugin not found:

```text
AskUserQuestion:
  Question: "Plugin '<name>' not found in marketplace.json or plugin.json missing. How to proceed?"
  Header: "Missing"
  Options:
  1. "Remove invalid plugin and continue"
  2. "Cancel operation"
```

If no valid plugins detected:

- Report: "No plugins detected for version bump. Use --plugins to specify manually."
- Exit

Mark "Validate plugin existence" as completed.

## Phase 3: Get Bump Type from User

Mark "Get bump type from user" as in_progress.

Display detected plugins:

```text
Plugins to bump: [list of plugin names]
```

```text
AskUserQuestion:
  Question: "What type of version bump?"
  Header: "Bump Type"
  Options:
  1. "patch - Bug fixes and minor changes (X.Y.Z -> X.Y.Z+1)"
  2. "minor - New features, backward compatible (X.Y.Z -> X.Y+1.0)"
  3. "major - Breaking changes (X.Y.Z -> X+1.0.0)"
  4. "Cancel"
```

Store selection as `$bump_type`.

If "Cancel" selected:

- Report: "Version bump cancelled"
- Exit

Mark "Get bump type from user" as completed.

## Phase 4: Read Current Versions

Mark "Read current versions" as in_progress.

Read and store current versions from:

1. **Root package.json**:
   - Read: `./package.json`
   - Extract: `$.version` -> `$root_package_version`

2. **Root marketplace.json**:
   - Read: `./.claude-plugin/marketplace.json`
   - Extract: `$.version` -> `$marketplace_version`

3. **Each affected plugin entry in marketplace.json**:
   - Find plugin in `$.plugins` array by name
   - Extract: `$.version` -> `$marketplace_plugin_versions[<plugin>]`

4. **Each plugin's individual plugin.json**:
   - Read: `<source>/.claude-plugin/plugin.json`
   - Extract: `$.version` -> `$plugin_versions[<plugin>]`

Mark "Read current versions" as completed.

## Phase 5: Calculate New Versions

Mark "Calculate new versions" as in_progress.

### Version Calculation Logic

For each version string `X.Y.Z`, apply bump type:

- **patch**: `X.Y.(Z+1)`
- **minor**: `X.(Y+1).0`
- **major**: `(X+1).0.0`

Calculate new versions for:

1. `$new_root_package_version` from `$root_package_version`
2. `$new_marketplace_version` from `$marketplace_version`
3. For each affected plugin:
   - `$new_marketplace_plugin_versions[<plugin>]` from `$marketplace_plugin_versions[<plugin>]`
   - `$new_plugin_versions[<plugin>]` from `$plugin_versions[<plugin>]`

Mark "Calculate new versions" as completed.

## Phase 6: Update Version Files

Mark "Update version files" as in_progress.

### 6.1: Update Root package.json

Edit `./package.json`:

- Change `"version": "$root_package_version"` to `"version": "$new_root_package_version"`

### 6.2: Update Root marketplace.json Version

Edit `./.claude-plugin/marketplace.json`:

- Change root `"version": "$marketplace_version"` to `"version": "$new_marketplace_version"`

### 6.3: Update Plugin Entries in marketplace.json

For each affected plugin in `$affected_plugins`:

- Edit `./.claude-plugin/marketplace.json`
- Locate plugin entry in `plugins` array by matching `"name": "<plugin>"`
- Change that entry's `"version": "$old"` to `"version": "$new"`

### 6.4: Update Individual plugin.json Files

For each affected plugin in `$affected_plugins`:

- Get source path from marketplace.json
- Edit `<source>/.claude-plugin/plugin.json`
- Change `"version": "$old"` to `"version": "$new"`

Mark "Update version files" as completed.

## Phase 7: Present Summary

Mark "Present summary" as completed.

Display comprehensive summary:

```markdown
## Version Bump Complete

### Bump Type
[patch/minor/major]

### Root Versions
| File | Before | After |
|------|--------|-------|
| package.json | X.Y.Z | X.Y.Z' |
| marketplace.json | X.Y.Z | X.Y.Z' |

### Plugin Versions
| Plugin | Before | After |
|--------|--------|-------|
| <plugin1> | X.Y.Z | X.Y.Z' |
| <plugin2> | X.Y.Z | X.Y.Z' |

### Files Modified
1. ./package.json
2. ./.claude-plugin/marketplace.json
3. ./<source1>/.claude-plugin/plugin.json
4. ./<source2>/.claude-plugin/plugin.json

### Next Steps
1. Review changes: `git diff`
2. Commit: `git add . && git commit -m "chore: bump versions"`
3. Push changes
```

## Error Handling

1. **No plugins detected**: Report "No plugins detected. Use --plugins to specify manually."

2. **Plugin not in marketplace**: Warn and allow user to skip or cancel.

3. **plugin.json not found**:
   - Report: "Missing plugin.json for '<plugin>' at <expected-path>"
   - Ask: Continue without this plugin or cancel?

4. **File read error**: Report file path and suggest checking permissions.

5. **Invalid version format**:
   - Report: "Invalid version format '<version>' in <file>. Expected X.Y.Z (semver)"
   - Exit

6. **PR not found** (when --pr specified):
   - Report: "PR #<number> not found"
   - Suggest: Check PR number or omit --pr flag

7. **No changes detected** (no --pr, no --plugins, empty git diff):
   - Report: "No changed files detected"
   - Suggest: Use --plugins to specify plugins manually
