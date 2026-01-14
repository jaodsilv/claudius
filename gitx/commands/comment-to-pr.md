---
description: Comments on a pull request when sharing status or responding. Use for PR discussion or posting summaries.
argument-hint: [PR] [comment | -l or --last | -c or --commit <commit> | -sc or --single-commit <commit> | -r or --review ["text"]] | -rr or --review-response ["text"]]
allowed-tools: Bash(gh pr:*), Bash(git branch:*), AskUserQuestion, Task(gitx:comment-handler:comment-handler), Skill(gitx:validating-comments)
model: sonnet
---

# Comment on Pull Request

Add a comment to a GitHub pull request. Delegates complex flows to gitx:comment-handler:comment-handler.

## Parse Arguments

Extract from $ARGUMENTS:

- **PR number** (optional): First numeric argument
- **Comment text** (optional): Text after PR number (unless flags used)
- **Flags**: See Flag Reference section

## Flag Reference

| Flag | Description |
|------|-------------|
| `-l`, `--last` | Post last Claude response from session |
| `-c <hash>`, `--commit <hash>` | Summary of commits since hash |
| `-sc <hash>`, `--single-commit <hash>` | Summary of single commit |
| `-r ["text"]`, `--review ["text"]` | Respond to review (auto-fetch or specified) |

**Combinations**: `-r` can combine with `-c` or `-sc` for commit evidence. Cannot combine `-r` with `--last`.

## Infer PR Number

If no PR number in arguments:

1. Get current branch: !`git branch --show-current`
2. Find PR: `gh pr view --json number,title`
3. If found: "Using PR #<number>: <title>"
4. If not found: List recent PRs via AskUserQuestion

## Flow Routing

### Simple: Inline Comment

If comment text provided directly in arguments:

1. Use skill `gitx:validating-comments`
2. Post: `gh pr comment <number> --body "$comment"`
3. Report success

### Complex: Delegate to Agent

For flag-based flows, delegate to gitx:comment-handler:comment-handler:

**Last Response** (`--last`):

````text
Task (gitx:comment-handler:comment-handler):
  target: [PR number]
  target_type: pr
  target_subtype: comment
  flow_type: last_response

  <latest responses>
  <response>
  ```markdown
  [last markdown text response]
  ```
  </response>
  <response>
  ```markdown
  [second last markdown text response]
  ```
  </response>
  ...
  </latest responses>
````

**Commit Summary** (`-c` or `-sc`):

```text
Task (gitx:comment-handler:comment-handler):
  target: [PR number]
  target_type: pr
  target_subtype: comment
  flow_type: commit_summary
  options:
    mode: [multi | single]
    commit: [hash]
```

**Review Response** (`-rr` or `--review-response`):

```text
Task (gitx:comment-handler:comment-handler):
  target: [PR number]
  target_type: pr
  target_subtype: comment
  flow_type: review_response
  options:
    review_text: [text or null]
    commit: [hash or null]
    commit_mode: [multi | single | null]
```

**Review Posting** (`-r` or `--review`):

```text
Task (gitx:comment-handler:comment-handler):
  target: [PR number]
  target_type: pr
  target_subtype: review
  flow_type: review_posting
  options:
    review_text: [text or null]
```

### Interactive: Template Selection

If no arguments or flags, use AskUserQuestion:

- Options: ["Summarize recent changes", "Request review", "Status update", "Post last response"]
- Route based on selection (delegate to agent for complex flows)

## Error Handling

| Error | Action |
|-------|--------|
| PR not found | Report and suggest checking number |
| Empty comment | Return to get comment text |
| gh not authenticated | Guide to `gh auth login` |
| Invalid flag combination | Report conflict |
| Agent failure | Report error from agent |
