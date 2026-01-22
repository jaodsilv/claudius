---
name: gitx:selecting-last-responses
description: >-
  Retrieves and presents recent Claude responses for selection. Use when users
  want to post previous responses to issues or PRs via --last flag.
allowed-tools: AskUserQuestion
model: sonnet
---

# Selecting Last Responses

Present recent Claude responses for user selection.

## IMPORTANT: Caller Responsibility

This skill CANNOT access conversation history. The **caller** (main agent or command) MUST:

1. Extract the last 4 valid responses from the conversation
2. Pass them to this skill in the `<latest responses>` format:

```text
<latest responses>
<response>
[full content of response 1]
</response>
<response>
[full content of response 2]
</response>
...
</latest responses>
```

If no responses are provided, return an error.

## Valid Response Criteria

A response is valid if it has:

- At least 4 lines of text, OR
- At least 140 characters

## Processing Provided Responses

1. Parse responses from `<latest responses>` input (provided by caller)
2. Extract title from first line of each response (before first newline)
3. Apply title truncation:
   - If title <= 80 chars: Use full text
   - If title > 80 chars: Use first 77 chars + "..."

## Edge Cases

| Condition | Action |
|-----------|--------|
| No `<latest responses>` provided | Error: "No responses provided. Caller must extract and pass responses from conversation." |
| 1-3 valid responses | Show all available (adjust options dynamically) |
| No valid responses | Error: "No valid Claude responses found (responses must have at least 4 lines or 140 characters). Cannot use --last flag." |
| First message in thread | Error: "No previous responses to post." |

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
