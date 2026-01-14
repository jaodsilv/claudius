---
name: gitx:performing-pr-preflight-checks
description: >-
  Performs pre-flight checks before PR operations. Use when creating PRs,
  merging, or modifying PR state to ensure operation will succeed.
allowed-tools: Bash(gh:*), Bash(git:*)
model: haiku
---

# Performing PR Preflight Checks

Validate prerequisites before PR operations to prevent failures.

## Check: Not on Protected Branch

If current branch is main/master:

- Report: "Cannot create PR from main branch"
- Suggest: Create a feature branch first
- Exit operation

## Check: Existing PR Status

Run: `gh pr view --json number,url,state 2>/dev/null`

If PR already exists:

- Report: "PR #`<number>` already exists for this branch"
- Show: URL and state
- Suggest: Use `/gitx:respond` to address feedback
- Exit operation

## Check: Remote Sync Status

```bash
git fetch origin
git log origin/<branch>..HEAD 2>/dev/null
```

| Condition             | Action                                          |
| --------------------- | ----------------------------------------------- |
| Local ahead of remote | Push first: `git push -u origin <branch>`       |
| Remote doesn't exist  | Create and push: `git push -u origin <branch>`  |
| In sync               | Proceed                                         |

## Check: CI Status (For Merge)

Run: `gh pr checks <number>`

| Result      | Action                          |
| ----------- | ------------------------------- |
| All passing | Proceed                         |
| Any failed  | Warn and ask to proceed anyway  |
| Pending     | Warn about incomplete checks    |

## Check: Review Approval (For Merge)

From PR JSON, check `reviews` field:

| Status            | Action                          |
| ----------------- | ------------------------------- |
| Approved          | Proceed                         |
| Changes requested | Block - resolve changes first   |
| Pending review    | Warn - may need approval        |
| No reviews        | Warn if reviews required        |
