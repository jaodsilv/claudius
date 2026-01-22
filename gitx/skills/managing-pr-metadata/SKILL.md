---
name: gitx:managing-pr-metadata
description: >-
  Centralized PR metadata management with lazy loading. Use when components
  need PR context or need to update metadata state (approved, resolveLevel).
allowed-tools: Bash(scripts/metadata-operations.sh:*)
model: haiku
---

# Managing PR Metadata

Centralized metadata management with lazy loading fallback.

## execution

```bash
scripts/metadata-operations.sh <operation> <worktree> [args...]
```

## Operations

### fetch

Fetch PR metadata from GitHub:

```bash
scripts/metadata-operations.sh fetch <worktree>
```

Fetches PR data for the current branch and writes to `<worktree>/.thoughts/pr/metadata.yaml`.

Output on success:

```json
{"status": "ok", "message": "PR metadata written to <path>"}
```

Output when no PR found (exit 0):

```json
{"pr": null, "branch": "<branch>", "noPr": true, "message": "No open PR found for branch: <branch>"}
```

#### Expected Fields

The metadata file contains:

| Field | Type | Description |
|-------|------|-------------|
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

### ensure

Check if metadata exists and is valid:

```bash
scripts/metadata-operations.sh ensure <worktree>
```

Output on success:

```json
{"status": "ok", "path": "<worktree>/.thoughts/pr/metadata.yaml"}
```

Output when metadata needs fetching (exit 1):

```json
{"status": "needs_fetch", "path": "<worktree>/.thoughts/pr/metadata.yaml"}
```

### read

Read a specific field from metadata:

```bash
scripts/metadata-operations.sh read <worktree> <field>
```

Returns the field value as JSON. Exits with error if metadata doesn't exist.

### update

Update a specific field:

```bash
scripts/metadata-operations.sh update <worktree> <field> <json_value>
```

Updates the field and sets `updatedAt` timestamp.

### set-resolve-level

Update the resolve level field:

```bash
scripts/metadata-operations.sh set-resolve-level <worktree> <level>
```

Values: `all`, `critical`, `important`

### set-approved

Update the approved field:

```bash
scripts/metadata-operations.sh set-approved <worktree> <bool>
```

Values: `true`, `false`

### remove-field

Remove a field from metadata:

```bash
scripts/metadata-operations.sh remove-field <worktree> <field>
```

Removes the specified field and updates `updatedAt` timestamp.

### post-push

Reset CI status and turn after pushing changes:

```bash
scripts/metadata-operations.sh post-push <worktree>
```

Performs three updates atomically:
- Clears `ciStatus` to empty array
- Sets `turn` to `CI-PENDING`
- Updates `latestCommit` to current HEAD

Output:

```json
{"status": "ok", "turn": "CI-PENDING", "ciStatus": "cleared", "latestCommit": "<sha>"}
```

### set-turn

Set the workflow turn state:

```bash
scripts/metadata-operations.sh set-turn <worktree> <turn>
```

Values: `CI-PENDING`, `CI-REVIEW`, `REVIEW`, `AUTHOR`

Output:

```json
{"status": "ok", "turn": "<turn>"}
```

### clear-ci-status

Clear the CI status array:

```bash
scripts/metadata-operations.sh clear-ci-status <worktree>
```

Output:

```json
{"status": "ok", "cleared": "ciStatus"}
```

### update-latest-commit

Update the latest commit from HEAD:

```bash
scripts/metadata-operations.sh update-latest-commit <worktree>
```

Output:

```json
{"status": "ok", "latestCommit": "<sha>"}
```
