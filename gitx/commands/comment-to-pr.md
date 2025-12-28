---
description: Comment on a pull request
argument-hint: "[PR] [comment | -l | --last]"
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

1. **Retrieve recent responses**: Get the last 4 valid responses from the current conversation thread
   - **Valid response criteria**: Must have at least 4 lines of text
   - Extract title from first line of each response (before first newline)
   - Title truncation rules:
     - If title ≤ 80 chars: Use full text
     - If title > 80 chars: Use first 77 chars + "..."

2. **Handle edge cases**:
   - **1-3 valid responses**: Show all available valid responses (adjust options list dynamically)
   - **No valid responses found**: Error: "No valid Claude responses found in current conversation
     (responses must have at least 4 lines). Cannot use --last flag."
   - **First message in thread**: Error: "This is the first message in the conversation.
     No previous responses to post."

3. **Present selection**: Use AskUserQuestion:
   - Question: "Which response would you like to post to PR #<number>?"
   - Header: "Response"
   - Options (newest to oldest, max 4):
     1. "🟢 <Response title>" - Most recent
     2. "🔵 <Response title>"
     3. "🔵 <Response title>"
     4. "🔵 <Response title>" - Oldest shown
   - Note: 🟢 = most recent, 🔵 = older responses

4. **Preview confirmation**: After selection, use AskUserQuestion:
   - Show preview: First 200 characters of selected response
   - Question: "Post this response to PR #<number>?"
   - Header: "Confirm"
   - Options:
     1. "✅ Post this response" - Proceed to validation
     2. "🔄 Select different response" - Return to step 3
     3. "❌ Cancel" - Abort posting

5. **Store selected response**: Save full content of selected response to `$comment` variable and proceed to validation.

## Validate Comment

Before posting, validate the comment:

1. **Empty check**: If comment text does not exist, is empty, or is whitespace-only:
   - Report error: "Cannot post empty comment"
   - Return to "Get Comment Text" section to request comment text

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

Post the comment using stdin to avoid shell escaping issues:
- `echo "$comment" | gh pr comment <number> --body-file -`

If the command fails, report the error and stop execution.

## Confirmation

Show the posted comment:
- PR number and title
- Comment preview (first 200 chars)
- Link to PR

## Error Handling

1. PR not found: Report error, suggest checking PR number.
2. Empty comment: Request comment text via "Get Comment Text" section.
3. Permission denied: Check repository access.
4. gh not authenticated: Guide to `gh auth login`.
5. gh command failure: Report the error message and stop execution.
6. No valid responses (--last flag): Report error and suggest using a different comment option.
7. First message in conversation (--last flag): Report error and suggest using a different comment option.
