---
name: gitx:performing-pr-preflight-checks
description: >-
  Performs pre-flight checks before PR operations. Use when creating PRs,
  merging, or modifying PR state to ensure operation will succeed.
allowed-tools: Bash(scripts/pr-preflight.sh:*)
model: sonnet
---

# Performing PR Preflight Checks

Validate prerequisites before PR operations to prevent failures.

## Usage

For PR creation checks:

```bash
scripts/pr-preflight.sh
```

For merge checks (includes CI and review status):

```bash
scripts/pr-preflight.sh --for-merge <pr_number>
```

## Checks Performed

### Always Run

1. **Protected Branch** - Ensures not on main/master
2. **Existing PR** - Checks if PR already exists for branch
3. **Remote Sync** - Verifies local/remote sync status

### Merge Mode Only (`--for-merge`)

1. **CI Status** - Checks if CI checks are passing
2. **Review Status** - Checks approval status

## Output

Returns JSON with check results:

```json
{
  "branch": "feature/my-branch",
  "all_passed": true,
  "checks": [
    {"check": "protected_branch", "status": "PASS", "message": "Not on protected branch"},
    {"check": "existing_pr", "status": "PASS", "message": "No existing PR"},
    {"check": "remote_sync", "status": "ACTION", "message": "Local is 2 commits ahead. Push required."}
  ]
}
```

## Status Values

| Status | Meaning |
|--------|---------|
| PASS | Check passed |
| FAIL | Check failed, blocks operation |
| WARN | Warning, can proceed with caution |
| ACTION | Action required before proceeding |
