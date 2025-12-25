---
description: Comment on a pull request
argument-hint: "[PR] [comment]"
allowed-tools: Bash(gh pr:*), Bash(git branch:*), AskUserQuestion
---

# Comment on Pull Request

Add a comment to a GitHub pull request. If PR number is not provided, uses the PR for the current branch.

## Parse Arguments

From $ARGUMENTS, extract:
- PR number (optional): First numeric argument
- Comment text (optional): Remaining text after PR number

## Infer PR Number

If no PR number provided:

1. Get current branch: !`git branch --show-current`
2. Find PR for branch: `gh pr view --json number,title 2>/dev/null`

If PR found:
- Use that PR number
- Show: "Using PR #<number>: <title>"

If no PR found:
- Use AskUserQuestion: "No PR found for current branch. Enter PR number:"
- Or list recent PRs: `gh pr list --state open --limit 5`
- Options: List PRs, plus "Enter PR number manually"

## Get Comment Text

If comment text not provided in arguments:

Use AskUserQuestion:
- "What would you like to comment on PR #<number>?"
- Options:
  1. "Summarize recent changes" - Generate summary from commits since PR creation
  2. "Request review" - Template for requesting review
  3. "Status update" - Template for progress update
  4. "Custom comment" - Let user provide text

### Auto-generated summaries

If "Summarize recent changes":
- Get commits since PR creation
- Get changed files summary
- Generate summary of recent work

If "Request review":
Template:

```text
## Ready for Review

This PR is ready for review. Key changes:
- <change 1>
- <change 2>

Please review when you have time. @<team-or-reviewer>
```

If "Status update":
Template:

```text
## Status Update

### Progress
- <completed item>

### Remaining
- <pending item>

### ETA
<estimated completion>
```

## Post Comment

Post the comment:
- `gh pr comment <number> --body "<comment>"`

## Confirmation

Show the posted comment:
- PR number and title
- Comment preview (first 200 chars)
- Link to PR

## Error Handling

- PR not found: Report error, suggest checking PR number
- Empty comment: Request comment text
- Permission denied: Check repository access
- gh not authenticated: Guide to `gh auth login`
