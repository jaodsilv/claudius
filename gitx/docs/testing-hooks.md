# Testing gitx Hook Scripts

This document provides a walkthrough for testing and debugging the gitx hook scripts.

## Enabling Debug Logging

All scripts support structured logging to help debug issues. To enable logging:

### Method 1: Environment Variables (Recommended)

Set these before running Claude Code:

```bash
# Enable debug logging
export GITX_DEBUG=1

# Also print logs to stderr (see logs in real-time)
export GITX_LOG_VERBOSE=1

# Custom log directory (optional, defaults to $TMP/gitx-hooks)
export GITX_LOG_DIR=/path/to/logs
```

### Method 2: Edit Main Scripts

Uncomment the debug lines at the top of the main scripts:

**`gitx/hooks/scripts/gitx-pre-command.sh`** (line 8-10):
```bash
# ============================================================================
# Debug Configuration - Set these to enable logging
# ============================================================================
export GITX_DEBUG=1          # Enable debug logging
export GITX_LOG_VERBOSE=1    # Also print to stderr
# ============================================================================
```

### Log File Location

Logs are written to: `$TMP/gitx-hooks/` (or `$GITX_LOG_DIR` if set)

Log files are named: `YYYYMMDD-HHMMSS-<script-name>-<pid>.log`

Example: `20260122-143052-pre-command-12345.log`

### Viewing Logs

```bash
# List recent logs
ls -lt $TMP/gitx-hooks/ | head -10

# View the most recent log
cat "$(ls -t $TMP/gitx-hooks/*.log | head -1)"

# Follow logs in real-time (with GITX_LOG_VERBOSE=1)
# Logs will appear on stderr as commands run
```

---

## Testing Individual Handlers

### Prerequisites

1. Navigate to a git repository with the gitx plugin installed
2. Enable debug logging (see above)
3. Have `gh` CLI authenticated (`gh auth status`)

### Test: Non-gitx Command (Pass-through)

**Purpose**: Verify non-gitx commands are passed through without processing.

```bash
# In Claude Code, type any non-gitx command
> hello world
```

**Expected**:
- Exit code 0
- Log shows "Not a gitx command, passing through"
- No blocking

---

### Test: Git Repository Validation

**Purpose**: Verify the hook blocks commands outside git repos.

```bash
# Navigate to a non-git directory
cd /tmp
# Then in Claude Code:
> /gitx:pr
```

**Expected**:
- Exit code 2 (block)
- Error: "Error: '/tmp' is not a git repository"
- Log shows "Not a git repository" error

---

### Test: `/gitx:pr` - New PR Creation

**Purpose**: Verify PR creation validation.

**Scenario A**: No existing PR
```bash
# On a branch without a PR
> /gitx:pr
```

**Expected**:
- Exit code 0 (proceed)
- Message: "No existing PR. Proceeding with PR creation."
- Log shows "No existing PR, proceeding with creation"

**Scenario B**: PR already exists
```bash
# On a branch with an existing PR
> /gitx:pr
```

**Expected**:
- Exit code 2 (block)
- Error: "PR already exists for branch '...'. Use /gitx:update-pr instead."

---

### Test: `/gitx:update-pr` - PR Update Validation

**Purpose**: Verify update-pr requires existing PR.

**Scenario A**: PR exists
```bash
# On a branch with a PR
> /gitx:update-pr
```

**Expected**:
- Exit code 0 (proceed)
- Message: "PR exists. Proceeding with update."

**Scenario B**: No PR
```bash
# On a branch without a PR
> /gitx:update-pr
```

**Expected**:
- Exit code 2 (block)
- Error: "No PR found for branch '...'. Use /gitx:pr to create one."

---

### Test: `/gitx:ignore` - Gitignore Creation

**Purpose**: Verify .gitignore is created if missing.

**Scenario A**: No .gitignore
```bash
# In a repo without .gitignore
rm .gitignore  # if it exists
> /gitx:ignore something
```

**Expected**:
- Exit code 0 (proceed)
- Message: "Created empty .gitignore file"
- `.gitignore` file created

**Scenario B**: .gitignore exists
```bash
# In a repo with .gitignore
> /gitx:ignore something
```

**Expected**:
- Exit code 0 (proceed)
- Log shows ".gitignore already exists"

---

### Test: `/gitx:fix-issue` and `/gitx:comment-to-issue` - Issue Validation

**Purpose**: Verify issue existence check.

**Scenario A**: Valid issue
```bash
# With a valid issue number
> /gitx:fix-issue 123
```

**Expected**:
- Exit code 0 (proceed)
- Message: "Issue #123 exists. Proceeding."

**Scenario B**: Invalid issue
```bash
# With a non-existent issue
> /gitx:fix-issue 999999
```

**Expected**:
- Exit code 2 (block)
- Error: "Issue #999999 not found"

**Scenario C**: Missing issue number
```bash
> /gitx:fix-issue
```

**Expected**:
- Exit code 2 (block)
- Error: "No issue number provided"

---

### Test: `/gitx:address-review` - Turn Validation

**Purpose**: Verify turn-based blocking.

**Prerequisites**: Create a PR and set up `.thoughts/pr/metadata.yaml`

**Scenario A**: Turn is AUTHOR
```bash
# With metadata.yaml having turn: AUTHOR
> /gitx:address-review
```

**Expected**:
- Exit code 0 (proceed)
- Message: "Turn: AUTHOR. Proceed with /gitx:address-review"

**Scenario B**: Turn is REVIEW (wrong turn)
```bash
# With metadata.yaml having turn: REVIEW
> /gitx:address-review
```

**Expected**:
- Exit code 2 (block)
- Error: "Current turn is REVIEW, not AUTHOR. Cannot address review."

**Scenario C**: Using --force to override
```bash
# With turn: REVIEW
> /gitx:address-review --force
```

**Expected**:
- Exit code 0 (proceed)
- Log shows FORCE=true

---

### Test: `/gitx:address-ci` - CI Status Handling

**Purpose**: Verify CI waiting and status checking.

**Scenario A**: CI has failures
```bash
# With failing CI checks
> /gitx:address-ci
```

**Expected**:
- Waits for CI to complete (logs show polling)
- Exit code 0 (proceed)
- Message: "CI Status: X failed checks. Proceed with /gitx:address-ci"
- Turn set to CI-REVIEW

**Scenario B**: All CI passes
```bash
# With all CI passing
> /gitx:address-ci
```

**Expected**:
- Exit code 2 (block)
- Error: "All CI checks passed. No failures to address."
- Turn set to REVIEW

---

### Test: `/gitx:merge` - Merge with Conflict Detection

**Purpose**: Verify merge attempts and conflict handling.

**Scenario A**: Clean merge
```bash
# On a branch that merges cleanly with main
> /gitx:merge
```

**Expected**:
- Exit code 2 (block - no LLM needed)
- Message: "Merge successful. main merged into <branch>."
- Log shows "Merge successful, no conflicts"

**Scenario B**: Merge conflicts
```bash
# On a branch with conflicts against main
> /gitx:merge
```

**Expected**:
- Exit code 0 (proceed - LLM handles conflicts)
- Message: "Merge has conflicts. Proceeding to conflict resolution."

---

### Test: `/gitx:rebase` - Rebase with Conflict Detection

**Purpose**: Verify rebase and stash handling.

**Scenario A**: Clean rebase
```bash
> /gitx:rebase
```

**Expected**:
- Exit code 2 (block)
- Message: "Rebase successful. Pushed to remote."

**Scenario B**: Dirty worktree (auto-stash)
```bash
# With uncommitted changes
echo "test" >> somefile.txt
> /gitx:rebase
```

**Expected**:
- Log shows "Stashing changes..."
- After success, log shows "Popping stash..."

**Scenario C**: Dirty worktree with --no-stash
```bash
echo "test" >> somefile.txt
> /gitx:rebase --no-stash
```

**Expected**:
- Exit code 2 (block)
- Error: "Working tree is dirty. Commit or stash changes first."

---

### Test: `/gitx:merge-pr` - PR Merge Validation

**Purpose**: Verify approval check before merge.

**Scenario A**: PR not approved
```bash
# With metadata showing approved: false
> /gitx:merge-pr
```

**Expected**:
- Exit code 2 (block)
- Error: "PR #X is not approved. Get reviewer approval first."

**Scenario B**: PR approved
```bash
# With metadata showing approved: true
> /gitx:merge-pr
```

**Expected**:
- Exit code 2 (block - always, but after successful merge)
- Message: "PR #X merged successfully!"

---

### Test: `/gitx:next-issue` - Issue Prioritization

**Purpose**: Verify priority-based issue selection.

**Scenario A**: Has open issues
```bash
> /gitx:next-issue
```

**Expected**:
- Exit code 2 (block - always)
- Shows highest priority issue (P0 > P1 > P2 > unlabeled)
- Log shows which priority level matched

**Scenario B**: No open issues
```bash
# In a repo with no open issues
> /gitx:next-issue
```

**Expected**:
- Exit code 2 (block)
- Error: "No open issues found."

---

### Test: `/gitx:remove-branch` - Branch Deletion

**Purpose**: Verify branch deletion safety checks.

**Scenario A**: Delete non-current branch
```bash
> /gitx:remove-branch feature-old
```

**Expected**:
- Exit code 2 (block - always)
- Message: "Branch 'feature-old' removed."

**Scenario B**: Delete current branch (without --force)
```bash
> /gitx:remove-branch
```

**Expected**:
- Exit code 2 (block)
- Error: "Cannot delete current branch '...'. Use --force to switch and delete."

**Scenario C**: Delete current branch (with --force)
```bash
> /gitx:remove-branch --force
```

**Expected**:
- Switches to main/default branch first
- Exit code 2 (block)
- Message: "Branch '...' removed."

---

### Test: `/gitx:remove-worktree` - Worktree Deletion

**Purpose**: Verify worktree deletion safety checks.

**Scenario A**: Clean worktree
```bash
> /gitx:remove-worktree /path/to/worktree
```

**Expected**:
- Exit code 2 (block - always)
- Message: "Worktree '/path/to/worktree' removed."

**Scenario B**: Dirty worktree (without --force)
```bash
# With uncommitted changes in worktree
> /gitx:remove-worktree /path/to/worktree
```

**Expected**:
- Exit code 2 (block)
- Error: "Worktree '...' has uncommitted changes. Use --force to remove anyway."

---

### Test: `/gitx:review` - Review Turn Validation

**Purpose**: Verify review can only run during REVIEW turn.

**Scenario A**: Turn is REVIEW
```bash
# With metadata having turn: REVIEW
> /gitx:review
```

**Expected**:
- Exit code 0 (proceed)
- Message: "Turn is REVIEW. Proceeding with review."

**Scenario B**: Turn is not REVIEW
```bash
# With metadata having turn: AUTHOR or CI-REVIEW
> /gitx:review
```

**Expected**:
- Exit code 2 (block)
- Error: "Current turn is X, not REVIEW. Cannot review."

---

## Testing the Stop Hook (Post-Command)

The Stop hook runs after Claude finishes responding for looping commands.

### Test: `/gitx:next-turn` Loop

**Purpose**: Verify the loop continues until PR approved.

```bash
# Start the loop
> /gitx:next-turn
```

**Expected behavior**:
1. Pre-command hook updates turn based on CI/review status
2. Claude processes the command
3. Stop hook checks if approved
4. If not approved, outputs JSON to continue loop
5. Repeat until `approved: true` in metadata

**Log verification**:
- Check `post-command-*.log` for "PR not yet approved, requesting loop continuation"

### Test: `/gitx:address-ci` Loop

**Purpose**: Verify CI fix loop continues until CI passes.

```bash
# With failing CI
> /gitx:address-ci
```

**Expected behavior**:
1. Pre-command waits for CI, lets Claude fix issues
2. Stop hook waits for CI again
3. If still failing, outputs JSON to continue loop
4. Repeat until all CI passes

---

## Debugging Tips

### 1. Check Log Files

```bash
# Find the most recent log
ls -lt $TMP/gitx-hooks/

# Search for errors
grep -l "ERROR" $TMP/gitx-hooks/*.log

# View specific handler logs
grep "Address-CI Handler" $TMP/gitx-hooks/*.log
```

### 2. Test Scripts Directly

You can test the pre-command script directly:

```bash
# Simulate a gitx command
echo '{"prompt": "/gitx:pr", "cwd": "/path/to/repo"}' | \
  GITX_DEBUG=1 GITX_LOG_VERBOSE=1 \
  bash /path/to/gitx/hooks/scripts/gitx-pre-command.sh
```

### 3. Check Exit Codes

- `exit 0` - Command proceeds to Claude
- `exit 2` - Command is blocked (hook handles it)

### 4. Verify Environment Variables

```bash
# In the handler, check these are set:
echo "WORKTREE=$WORKTREE"
echo "ARGS=$ARGS"
echo "METADATA_FILE=$METADATA_FILE"
echo "CLAUDE_PLUGIN_ROOT=$CLAUDE_PLUGIN_ROOT"
```

### 5. Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Not a git repository" | Wrong WORKTREE path | Check path conversion |
| "No metadata file" | PR not created yet | Run `/gitx:pr` first |
| Handler not found | Wrong HANDLERS_DIR | Check script location |
| yq/jq errors | Tools not installed | Install yq and jq |
| gh errors | Not authenticated | Run `gh auth login` |

---

## Log Format Reference

Each log entry includes:

```
[<elapsed_ms>ms] <LEVEL> <message>
```

Levels:
- `DEBUG` - Variable values and state
- `INFO` - Normal operations
- `WARN` - Potential issues
- `ERROR` - Failures

Sections:
- `======== Section Name ========` - Major phases
- `JSON <label>:` - Pretty-printed JSON data
- `CMD $ <command>` - Shell commands executed
- `EXIT code=X reason="..."` - Script termination
