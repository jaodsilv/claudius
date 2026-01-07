---
name: gitx:validating-comments
description: >-
  Validates comment content before posting to GitHub. Use when posting comments
  to issues or PRs to ensure compliance with size limits and content requirements.
version: 1.0.0
allowed-tools: AskUserQuestion
model: haiku
---

# Validating Comments

Validate comment content before posting to GitHub issues or PRs.

## Validation Steps

### 1. Empty Check

If comment text does not exist, is empty, or is whitespace-only:

- Report error: "Cannot post empty comment"
- Return to caller to request comment text

### 2. Size Check

Check comment length against GitHub limits:

| Condition | Action |
|-----------|--------|
| > 60,000 chars | Hard limit exceeded - must resolve |
| > 20,000 chars | Warning - long comment |
| <= 20,000 chars | Pass validation |

**Hard limit exceeded (> 60K):**

Use AskUserQuestion: "Comment exceeds GitHub's 60K character limit. How would you like to proceed?"

Options:

1. "Shorten text" - Let Claude summarize/condense the content
2. "Truncate as-is" - Cut off at 60K characters
3. "Split into multiple comments" - Post as sequential comments
4. "Abort" - Cancel posting

**Warning threshold (> 20K but <= 60K):**

Use AskUserQuestion: "Comment is very long (>20K characters). How would you like to proceed?"

Options:

1. "Shorten text" - Let Claude summarize/condense the content
2. "Abort" - Cancel posting

## Return Values

| Result | Next Step |
|--------|-----------|
| Pass | Proceed to post comment |
| Empty | Return to get comment text |
| Abort | Cancel operation |
| Shortened/Truncated | Re-validate new content |
