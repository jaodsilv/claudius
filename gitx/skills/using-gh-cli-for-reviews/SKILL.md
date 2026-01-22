---
name: gitx:using-gh-cli-for-reviews
description: >-
  GitHub CLI operations for PR reviews. Use when checking PR ownership,
  listing reviews, creating comments, or minimizing resolved comments.
allowed-tools: Bash(scripts/gh-review-operations.sh:*)
model: sonnet
---

# Using GH CLI for Reviews

GitHub CLI operations for PR review workflows.

## Usage

```bash
scripts/gh-review-operations.sh <operation> [args...]
```

## Operations

### check-owner

Check if current user is the PR owner (determines available actions):

```bash
scripts/gh-review-operations.sh check-owner <pr_number>
```

Output:

```json
{"is_owner": true, "user": "username", "can_approve": false}
```

**Note**: PR owners cannot approve/request changes on their own PRs.

### list-reviews

List non-minimized reviews and review threads from metadata file:

```bash
scripts/gh-review-operations.sh list-reviews <worktree>
```

Reads from `$worktree/.thoughts/pr/metadata.yaml` and returns:

```json
{
  "reviews": [...],
  "reviewThreads": [...],
  "latestMinimizedReview": {...}
}
```

**Notes**:

- Only returns non-minimized reviews and threads (already filtered in metadata)
- Includes `latestMinimizedReview` for context (previous review state)
- If metadata file doesn't exist, returns `{"error": "...", "needs_fetch": true}` (exit 1)
- Caller should trigger `Task(gitx:pr:metadata-fetcher)` with worktree, then retry

### create-comment

Create a review comment (for owner reviewing own PR):

```bash
scripts/gh-review-operations.sh create-comment <pr_number> "<body>"
```

### create-pr-comment

Create a regular PR comment (response to review):

```bash
scripts/gh-review-operations.sh create-pr-comment <pr_number> "<body>"
```

### minimize-comment

Minimize (hide) a comment with a reason:

```bash
scripts/gh-review-operations.sh minimize-comment <node_id> [reason]
```

Reasons: `RESOLVED`, `OUTDATED`, `OFF_TOPIC`, `ABUSE`, `SPAM`, `DUPLICATE`

### get-latest-comment

Get the latest non-review comment on a PR:

```bash
scripts/gh-review-operations.sh get-latest-comment <pr_number>
```

## Owner vs Non-Owner Actions

| Action | Owner Can | Non-Owner Can |
|--------|-----------|---------------|
| Create review comment | Yes (COMMENTED only) | Yes (all states) |
| Approve PR | No | Yes |
| Request changes | No | Yes |
| Minimize comments | Yes | Yes |
