---
description: Comment on a GitHub issue
argument-hint: "[ISSUE] [comment | -l | --last]"
allowed-tools: Bash(gh issue:*), Bash(git branch:*), AskUserQuestion
---

# Comment on Issue

Add a comment to a GitHub issue. If issue number is not provided, attempts to infer from current branch.

## Parse Arguments

From $ARGUMENTS, extract:
- Issue number (optional): First numeric argument, or "#123" format
- Comment text (optional): Remaining text after issue number
- `--last` or `-l` flag: If present, triggers last response flow

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
  4. "Post last response" - Share Claude's latest response from this session

### Auto-generated summaries

If "Summarize recent work":
- Get recent commits: `git log --oneline -10`
- Get changed files: `git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat`
- Generate summary of changes made

If "Report progress":
Template:

```text
## Progress Update

### Completed
-

### In Progress
-

### Blockers
- None
```

If "Post last response" (or `--last` flag used):

1. **Retrieve recent responses**: Get the last 4 valid responses from the current conversation thread
   - **Valid response criteria**: Must have at least 4 lines of text OR 140 characters
   - Extract title from first line of each response (before first newline)
   - Title truncation rules:
     - If title ≤ 80 chars: Use full text
     - If title > 80 chars: Use first 77 chars + "..."

2. **Handle edge cases**:
   - **1-3 valid responses**: Show all available valid responses (adjust options list dynamically)
   - **No valid responses found**: Error: "No valid Claude responses found in current conversation
     (responses must have at least 4 lines or 140 characters). Cannot use --last flag."
   - **First message in thread**: Error: "This is the first message in the conversation.
     No previous responses to post."

3. **Present selection**: Use AskUserQuestion:
   - Question: "Which response would you like to post to issue #<number>?"
   - Header: "Response"
   - Options (newest to oldest, max 4):
     1. "🟢 <Response title>" - Most recent
     2. "🔵 <Response title>"
     3. "🔵 <Response title>"
     4. "🔵 <Response title>" - Oldest shown
   - Note: 🟢 = most recent, 🔵 = older responses

4. **Preview confirmation**: After selection, use AskUserQuestion:
   - Show preview: First 200 characters of selected response
   - Question: "Post this response to issue #<number>?"
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

Post the comment:
- `gh issue comment <number> --body "$comment"`

If the command fails, report the error and stop execution.

## Confirmation

Show the posted comment:
- Issue number and title
- Comment preview (first 200 chars)
- Link to issue

## Error Handling

1. Issue not found: Report error, suggest checking issue number.
2. Empty comment: Request comment text via "Get Comment Text" section.
3. Permission denied: Check repository access.
4. gh not authenticated: Guide to `gh auth login`.
5. gh command failure: Report the error message and stop execution.
6. No valid responses (--last flag): Report error and suggest using a different comment option.
7. First message in conversation (--last flag): Report error and suggest using a different comment option.
