---
description: >-
  Centralized PR metadata management with flag-based CLI. Use when components
  need PR context or need to update metadata state (approved, resolveLevel).
user-invocable: true
allowed-tools: Bash(*/scripts/metadata/metadata-operations.sh *)
model: haiku
---

# Managing PR Metadata

Centralized metadata management with lazy loading fallback.

## Execution

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/metadata/metadata-operations.sh [flags]
```

## Flags

| Flag | Description |
| :--- | :---------- |
| `--worktree <path>` | Working directory (default: .) |
| `--get [<fields>]` | Get metadata fields (comma-separated, or all if omitted) |
| `--set <key> <value>` | Set a metadata field (repeatable) |
| `--clear <fields>` | Clear/delete fields (comma-separated) |
| `--refresh [<fields>]` | Refresh metadata from GitHub |
| `--refresh-areas <areas>` | Refresh by area (comma-separated) |
| `--wait-ci` | Wait for CI to complete (max 10 min) |
| `--format <json\|yaml>` | Output format (default: json) |
| `--output <filepath>` | Write output to file |
| `--fields` | List all known fields |
| `--areas` | List all areas |
| `--set-fields` | List populated fields in metadata |

## --get Output Rules

- No fields → entire metadata as JSON (or --format)
- 1 field → raw value only (unless --format specified)
- 2+ fields → key-value JSON (or --format)

## Areas

| Area | Fields |
| :--- | :----- |
| no-pr | branch, latestCommit, linkedIssue, base, author, pr |
| pr | pr, author, title, description, branch, base |
| issue | linkedIssue |
| worktree | worktree, branch |
| review | latestReviews, reviewThreads, latestMinimizedReview, latestReviewedCommit, reviewCount, latestCommit |
| comments | latestComments, historicalComments |
| ci | ciStatus, ciResult |
| turn | ciStatus, ciResult, latestComments, historicalComments, turn |

## Expected Fields

| Field | Type | Description |
| :---- | :--- | :---------- |
| pr | number | PR number |
| author | string | PR author login |
| branch | string | Feature branch name |
| worktree | string | Absolute path to worktree |
| title | string | PR title |
| description | string | PR body |
| base | string | Base branch (e.g., main) |
| linkedIssue | number\|null | Issue number from branch name |
| latestReviews | array | Non-minimized global reviews |
| reviewThreads | array | Non-collapsed inline comments |
| latestMinimizedReview | object\|null | Latest minimized review |
| latestReviewedCommit | string\|null | Last reviewed commit SHA |
| ciStatus | array | CI check results |
| ciResult | string\|null | Aggregated CI result (SUCCESS\|FAILURE\|ONGOING) |
| latestComments | array | Comments after oldest review |
| historicalComments | array | Comments before oldest review |
| reviewCount | number | Count of review rounds |
| turn | string | Current turn (REVIEW\|AUTHOR\|CI-PENDING\|CI-REVIEW) |
| latestCommit | string\|null | Latest commit SHA |
| reviewDecision | string\|null | GitHub review status |
| approved | boolean | Whether PR is approved |
| resolveLevel | string | Feedback scope (all\|critical\|important) |
| createdAt | string | ISO-8601 creation timestamp |
| updatedAt | string | ISO-8601 update timestamp |

## Examples

```bash
# List all known fields
metadata-operations.sh --fields

# List all areas
metadata-operations.sh --areas

# Refresh metadata from GitHub
metadata-operations.sh --worktree /path --refresh

# Get specific fields
metadata-operations.sh --worktree /path --get pr,branch

# Get single field (raw value)
metadata-operations.sh --worktree /path --get pr

# Set turn and approved
metadata-operations.sh --worktree /path --set turn AUTHOR --set approved true

# Clear CI status
metadata-operations.sh --worktree /path --clear ciStatus,ciResult

# Post-push equivalent
metadata-operations.sh --worktree /path --clear ciStatus --set ciResult '"ONGOING"' --set turn CI-PENDING
```
