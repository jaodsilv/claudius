---
description: Bump plugin versions based on PR changes or explicit list
argument-hint: "[--pr <number>] [--plugins <list>]"
allowed-tools: ["Bash(gh:*)", "Bash(git:*)", "Read", "Edit", "AskUserQuestion", "TodoWrite"]
---

# Bump Plugin Versions

Bump versions for plugins affected by changes in a PR or worktree.
Updates package.json (root), marketplace.json (root and plugin entries), and individual plugin.json files.

## Parse Arguments

From $ARGUMENTS, extract:

1. `--pr <number>`: Optional PR number to analyze for changed files
2. `--plugins <list>`: Optional comma-separated list of plugins to bump (e.g., `cc,gitx`)

## Initialize Progress Tracking

```text
TodoWrite:
  todos:
    - content: "Detect affected plugins"
      status: "pending"
      activeForm: "Detecting affected plugins"
    - content: "Validate plugin existence"
      status: "pending"
      activeForm: "Validating plugin existence"
    - content: "Get bump type from user"
      status: "pending"
      activeForm: "Getting bump type from user"
    - content: "Read current versions"
      status: "pending"
      activeForm: "Reading current versions"
    - content: "Calculate new versions"
      status: "pending"
      activeForm: "Calculating new versions"
    - content: "Update version files"
      status: "pending"
      activeForm: "Updating version files"
    - content: "Present summary"
      status: "pending"
      activeForm: "Presenting summary"
```

## Phase 1: Detect Affected Plugins

Mark "Detect affected plugins" as in_progress.

### If --plugins provided

Parse the comma-separated list into `$affected_plugins` array.
Set `$detection_method` = "explicit --plugins flag"
Skip to Phase 2.

### If --plugins NOT provided

#### Step 1: Determine source of changed files

If `--pr` provided:

```bash
gh pr view <pr-number> --json files --jq '.files[].path'
```

Handle command result:

- If command fails (any error): Exit immediately (gh command will display the error)

Set `$detection_method` = "PR #<pr-number> files"

If `--pr` NOT provided:

1. Check if current worktree has associated PR:

   ```bash
   gh pr view --json number
   ```

   Handle command result:
   - If command succeeds: Extract PR number and set `$detection_method` = "PR #X files"
   - If "no pull requests found" error: Fall back to git diff (step 3)
   - If other error (auth, network, rate limit): Report error to user and exit

2. If PR exists: Get its number and fetch files as above

3. If no PR: Get all changes (committed, staged, and unstaged):

   First, validate git diff is possible:

   ```bash
   # Determine base branch (main or master)
   git rev-parse --verify main 2>&1 || git rev-parse --verify master 2>&1
   ```

   - If both fail: Report "Neither 'main' nor 'master' branch exists" and exit
   - Set `$base_branch` to whichever exists (prefer `main`)

   ```bash
   # Check if on base branch
   git branch --show-current
   ```

   - If current branch equals `$base_branch`:
     Report "Cannot diff: currently on $base_branch branch. Use --plugins to specify manually."
     and exit

   Then get changes:

   ```bash
   # Committed changes from base branch
   git diff $base_branch...HEAD --name-only
   # Staged changes
   git diff --staged --name-only
   # Unstaged changes
   git diff --name-only
   ```

   - If any git command fails: Exit immediately (git will display the error)

   Combine and deduplicate results into changed files list.
   Set `$detection_method` = "git diff from $base_branch"

#### Step 2: Build plugin-to-directory mapping

Read `./.claude-plugin/marketplace.json`:

- If file not found: Report "marketplace.json not found at ./.claude-plugin/marketplace.json" and exit
- If invalid JSON: Report "Invalid JSON in marketplace.json" and exit
- If `$.plugins` array missing: Report "Missing 'plugins' array in marketplace.json" and exit

Extract each plugin's `source` field to build a mapping:

```text
For each plugin in $.plugins:
  - Extract name: $.name
  - Extract source: $.source (e.g., "./cc", "./brainstorm.claude")
  - Normalize source: Remove leading "./" if present
  - Store mapping: directory_prefix -> plugin_name
```

#### Step 3: Map changed files to plugins

For each changed file path:

1. Check if path starts with any known plugin directory prefix
2. If match found, add that plugin to `$affected_plugins` (deduplicated)

### Report Detection Results

Report to user:

- Detection method: `$detection_method`
- Number of changed files analyzed: (count if applicable, N/A for --plugins)
- Affected plugins: `$affected_plugins`

Mark "Detect affected plugins" as completed.

## Phase 2: Validate Plugin Existence

Mark "Validate plugin existence" as in_progress.

For each plugin in `$affected_plugins`:

1. Verify plugin exists in marketplace.json (has entry in `$.plugins` array)
2. Get the source path from marketplace.json
3. Verify plugin.json exists at: `./<source>/.claude-plugin/plugin.json`

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
   - If file not found or invalid JSON: Report error and exit
   - Extract: `$.version` -> `$root_package_version`
   - If `$.version` missing: Create field with value `"0.0.0"` and set `$root_package_version` = `"0.0.0"`

2. **Root marketplace.json**:
   - Read: `./.claude-plugin/marketplace.json`
   - If file not found or invalid JSON: Report error and exit
   - Extract: `$.version` -> `$marketplace_version`
   - If `$.version` missing: Create field with value `"0.0.0"` and set `$marketplace_version` = `"0.0.0"`

3. **Each affected plugin entry in marketplace.json**:
   - Find plugin in `$.plugins` array by name
   - If plugin not found: Report error and exit
   - Extract: `$.version` -> `$marketplace_plugin_versions[<plugin>]`
   - If `$.version` missing: Create field with value `"0.0.0"` and set `$marketplace_plugin_versions[<plugin>]` = `"0.0.0"`

4. **Each plugin's individual plugin.json**:
   - Read: `./<source>/.claude-plugin/plugin.json`
   - If file not found or invalid JSON: Report error and exit
   - Extract: `$.version` -> `$plugin_versions[<plugin>]`
   - If `$.version` missing: Create field with value `"0.0.0"` and set `$plugin_versions[<plugin>]` = `"0.0.0"`

### Validate Version Format

For each version read (`$root_package_version`, `$marketplace_version`, `$marketplace_plugin_versions[*]`, `$plugin_versions[*]`):

- Validate matches semver pattern: `^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$`
  - This accepts: `1.0.0`, `1.0.0-alpha`, `1.0.0-beta.1`, `1.0.0-rc.1`
- If invalid:
  - Report: "Invalid version format '<version>' in <file>. Expected X.Y.Z or X.Y.Z-prerelease (semver)"
  - Exit with error

**Note**: Pre-release suffixes (e.g., `-beta.1`) are stripped before version comparison and bump
calculation. The new version will not include the pre-release suffix.

If any version contains a pre-release suffix:

```text
AskUserQuestion:
  Question: "Version '<version>' has pre-release suffix '<suffix>'. The bump will produce a release version (e.g., 1.0.0-beta.1 → 1.0.1). Continue?"
  Header: "Pre-release"
  Options:
  1. "Yes, proceed with release version"
  2. "Cancel and handle manually"
```

If "Cancel" selected: Exit with message "Version bump cancelled due to pre-release version."

### Version Sync Validation

For each affected plugin, compare:

- `$marketplace_plugin_versions[<plugin>]` vs `$plugin_versions[<plugin>]`

If versions differ:

```text
AskUserQuestion:
  Question: "Version mismatch for '<plugin>': marketplace.json has X.Y.Z, plugin.json has A.B.C. Which to use as base?"
  Header: "Mismatch"
  Options:
  1. "Use marketplace.json version (X.Y.Z)"
  2. "Use plugin.json version (A.B.C)"
  3. "Use higher version"
  4. "Cancel and fix manually"
```

Apply selected resolution:

- Options 1-3: Use selected version as base for both files
- Option 4: Exit with error

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

### 6.0: Initialize Edit Tracking

Create `$successful_edits` list to track completed updates.

### 6.1: Update Root package.json

Edit `./package.json`:

- Change `"version": "$root_package_version"` to `"version": "$new_root_package_version"`
- On success: Add `./package.json` to `$successful_edits`
- On failure: Go to Error Recovery

### 6.2: Update Root marketplace.json Version

Edit `./.claude-plugin/marketplace.json`:

- Change root `"version": "$marketplace_version"` to `"version": "$new_marketplace_version"`
- On success: Add `./.claude-plugin/marketplace.json (root version)` to `$successful_edits`
- On failure: Go to Error Recovery

### 6.3: Update Plugin Entries in marketplace.json

For each affected plugin in `$affected_plugins`:

- Edit `./.claude-plugin/marketplace.json`
- Locate plugin entry in `plugins` array by matching `"name": "<plugin>"`
- Change that entry's `"version": "$old"` to `"version": "$new"`
- On success: Add `./.claude-plugin/marketplace.json (plugin: <plugin>)` to `$successful_edits`
- On failure: Go to Error Recovery

### 6.4: Update Individual plugin.json Files

For each affected plugin in `$affected_plugins`:

- Get source path from marketplace.json
- Edit `./<source>/.claude-plugin/plugin.json`
- Change `"version": "$old"` to `"version": "$new"`
- On success: Add `./<source>/.claude-plugin/plugin.json` to `$successful_edits`
- On failure: Go to Error Recovery

### Error Recovery

If any edit fails:

1. Report which file failed and the error message
2. List files already modified: `$successful_edits`
3. Provide recovery command using all paths from `$successful_edits`:

   ```bash
   git checkout -- $successful_edits
   ```

   Example output (with actual paths from tracking list):

   ```bash
   git checkout -- ./package.json ./.claude-plugin/marketplace.json ./cc/.claude-plugin/plugin.json
   ```

4. Exit with error

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
[List all paths from $successful_edits]

### Next Steps
1. Review changes: `git diff`
2. Commit: `git add . && git commit -m "chore: bump versions"`
3. Push changes
```

## Error Handling

All errors result in immediate exit unless otherwise specified.

1. **No plugins detected**: Report "No plugins detected. Use --plugins to specify manually." and exit.

2. **Plugin not in marketplace**: Warn and allow user to skip or cancel.

3. **plugin.json not found**:
   - Report: "Missing plugin.json for '<plugin>' at <expected-path>"
   - Ask: Continue without this plugin or cancel?

4. **File read error**: Report file path and error message, then exit.

5. **Invalid JSON**: Report file path and parsing error, then exit.

6. **Invalid version format**:
   - Report: "Invalid version format '<version>' in <file>. Expected X.Y.Z or X.Y.Z-prerelease (semver)"
   - Exit

7. **PR not found** (when --pr specified): Exit (gh command will display the error).

8. **GitHub API error** (auth, network, rate limit): Exit (gh command will display the error).

9. **Git command error**: Exit (git command will display the error).

10. **No changes detected** (no --pr, no --plugins, empty git diff):
    - Report: "No changed files detected"
    - Suggest: Use --plugins to specify plugins manually
    - Exit

11. **Base branch not found**: Report "Neither 'main' nor 'master' branch exists" and exit.

12. **On base branch**: Report "Cannot diff: currently on <branch> branch. Use --plugins to specify plugins manually." and exit.
