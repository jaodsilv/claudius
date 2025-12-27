---
description: Comment on a pull request
argument-hint: "[PR] [comment | --last]"
allowed-tools: Bash(gh pr:*), Bash(git branch:*), AskUserQuestion
---

# Comment on Pull Request

Add a comment to a GitHub pull request. If PR number is not provided, uses the PR for the current branch.

## Parse Arguments

From $ARGUMENTS, extract:
- PR number (optional): First numeric argument
- Comment text (optional): Remaining text after PR number
- `--last` or `-l` flag: If present, triggers last response flow

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
  4. "Post last response" - Share Claude's latest response from this session
  5. "Custom comment" - Let user provide text

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

If "Post last response" (or `--last` flag used):

Retrieve Claude's last response from the current session context and use it as the comment text.

## Validate Comment

Before posting, validate the comment:

1. **Empty check**: If comment text does not exist, is empty, or is whitespace-only:
   - Report error: "Cannot post empty comment"
   - Fall back to Error Handling #2

2. **Size check**: Check comment length:
   - If > 60,000 characters:
     - Use AskUserQuestion: "Comment exceeds GitHub's 60K character limit. How would you like to proceed?"
     - Options:
       1. "Shorten text" - Let Claude summarize/condense the content
       2. "Truncate as-is" - Cut off at 60K characters
       3. "Split into multiple comments" - Post as sequential comments
       4. "Abort" - Cancel posting
   - If > 20,000 characters (but ≤ 60,000):
     - Use AskUserQuestion: "Comment is very long (>20K characters). How would you like to proceed?"
     - Options:
       1. "Shorten text" - Let Claude summarize/condense the content
       2. "Abort" - Cancel posting

## Post Comment

Post the comment:
- `gh pr comment <number> --body "$comment"`

## Confirmation

Show the posted comment:
- PR number and title
- Comment preview (first 200 chars)
- Link to PR

## Error Handling

1. PR not found: Report error, suggest checking PR number.
2. Empty comment: Request comment text.
3. Permission denied: Check repository access.
4. gh not authenticated: Guide to `gh auth login`.
