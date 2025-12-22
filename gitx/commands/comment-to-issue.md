---
description: Comment on a GitHub issue
argument-hint: "[ISSUE] [comment]"
allowed-tools: Bash(gh issue:*), Bash(git branch:*), AskUserQuestion
---

# Comment on Issue

Add a comment to a GitHub issue. If issue number is not provided, attempts to infer from current branch.

## Parse Arguments

From $ARGUMENTS, extract:
- Issue number (optional): First numeric argument, or "#123" format
- Comment text (optional): Remaining text after issue number

## Infer Issue Number

If no issue number provided:

1. Get current branch: !`git branch --show-current`
2. Parse branch name for issue number patterns:
   - `feature/issue-123-description` → 123
   - `bugfix/123-description` → 123
   - `fix/issue-456` → 456
   - `feature/#789-something` → 789

If pattern found:
- Use that issue number
- Verify issue exists: `gh issue view <number> --json number,title`

If no pattern found or issue doesn't exist:
- Use AskUserQuestion: "Which issue would you like to comment on?"
- Show recent open issues: `gh issue list --state open --limit 5`
- Options: List issues, plus "Enter issue number manually"

## Get Comment Text

If comment text not provided in arguments:

Use AskUserQuestion:
- "What would you like to comment on issue #<number>?"
- Options:
  1. "Summarize recent work" - Generate summary from git log
  2. "Report progress" - Template for progress update
  3. "Ask a question" - Template for clarification
  4. "Custom comment" - Let user provide text

### Auto-generated summaries

If "Summarize recent work":
- Get recent commits: `git log --oneline -10`
- Get changed files: `git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat`
- Generate summary of changes made

If "Report progress":
Template:

```
## Progress Update

### Completed
-

### In Progress
-

### Blockers
- None
```

## Post Comment

Post the comment:
- `gh issue comment <number> --body "<comment>"`

## Confirmation

Show the posted comment:
- Issue number and title
- Comment preview (first 200 chars)
- Link to issue

## Error Handling

- Issue not found: Report error, suggest checking issue number
- Empty comment: Request comment text
- Permission denied: Check repository access
- gh not authenticated: Guide to `gh auth login`
