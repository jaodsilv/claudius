---

description: Comments on a GitHub issue when sharing progress or updates. Use for team communication or documenting work.
argument-hint: "[ISSUE] [comment | -l | --last | -c <commit> | --commit <commit> | -sc <commit> | --single-commit <commit>]"
allowed-tools: Bash(gh issue:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git rev-parse:*), AskUserQuestion, Skill(gitx:validating-comments), Skill(gitx:selecting-last-responses), Skill(gitx:generating-commit-summaries)
model: sonnet
---

# Comment on Issue

Add a comment to a GitHub issue. If issue number is not provided, attempts to infer from current branch.

## Parse Arguments

From $ARGUMENTS, extract:
- Issue number (optional): First numeric argument, or "#123" format
- Comment text (optional): Remaining text after issue number
- `--last` or `-l` flag: If present, triggers last response flow
- `-c` or `--commit` flag with value: If present, triggers commit-since summary flow
- `-sc` or `--single-commit` flag with value: If present, triggers single-commit summary flow

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
- Get changed files: `git diff --stat HEAD~5..HEAD`
- Generate summary of changes made

### Commit-based summaries

If `-c <commit>` or `--commit <commit>` flag used:

- Use skill `gitx:generating-commit-summaries` with multi-commit mode
- Target: issue #\<number\>

If `-sc <commit>` or `--single-commit <commit>` flag used:

- Use skill `gitx:generating-commit-summaries` with single-commit mode
- Target: issue #\<number\>

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

- Use skill `gitx:selecting-last-responses`
- Target: issue #\<number\>

## Validate Comment

Use skill `gitx:validating-comments` to validate `$comment` before posting.

If validation fails with empty comment, return to "Get Comment Text" section.

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
8. Invalid commit hash: Report "Commit '<hash>' not found in repository. Please verify the commit hash."
9. Commit not in history: Report "Commit '<hash>' exists but is not in current branch's history."
