---
name: gitx:selecting-last-responses
description: >-
  Retrieves and presents recent Claude responses for selection. Use when users
  want to post previous responses to issues or PRs via --last flag.
version: 1.0.0
allowed-tools: AskUserQuestion
model: haiku
---

# Selecting Last Responses

Retrieve and present recent Claude responses for user selection.

## Valid Response Criteria

A response is valid if it has:

- At least 4 lines of text, OR
- At least 140 characters

## Retrieval Process

1. Get the last 4 valid responses from current conversation thread
2. Extract title from first line of each response (before first newline)
3. Apply title truncation:
   - If title <= 80 chars: Use full text
   - If title > 80 chars: Use first 77 chars + "..."

## Edge Cases

| Condition | Action |
|-----------|--------|
| 1-3 valid responses | Show all available (adjust options dynamically) |
| No valid responses | Error: "No valid Claude responses found in current conversation (responses must have at least 4 lines or 140 characters). Cannot use --last flag." |
| First message in thread | Error: "This is the first message in the conversation. No previous responses to post." |

## Selection Interface

Use AskUserQuestion:

- Question: "Which response would you like to post to [target] #\<number\>?"
- Header: "Response"
- Options (newest to oldest, max 4):
  1. "[green] \<Response title\>" - Most recent
  2. "[blue] \<Response title\>"
  3. "[blue] \<Response title\>"
  4. "[blue] \<Response title\>" - Oldest shown

## Confirmation

After selection, use AskUserQuestion:

- Show preview: Full selected response
- Question: "Post this response to [target] #\<number\>?"
- Header: "Confirm"
- Options:
  1. "Post this response" - Proceed to validation
  2. "Select different response" - Return to selection
  3. "Cancel" - Abort posting

## Output

Store full content of selected response to `$comment` variable for validation.
