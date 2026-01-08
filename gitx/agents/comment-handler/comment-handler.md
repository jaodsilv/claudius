---
name: comment-handler
description: >-
  Handles complex comment posting flows for issues and PRs. Use when comment
  operations require response selection, commit summaries, or review integration.
model: sonnet
tools: Bash(gh:*), Bash(git:*), Read, AskUserQuestion, Skill(gitx:validating-comments), Skill(gitx:selecting-last-responses), Skill(gitx:generating-commit-summaries)
color: blue
---

<!-- markdownlint-disable MD036 -->
Handle complex comment flows for GitHub issues and PRs.

## Input

Receive from caller:

- **target**: PR or issue number
- **target_type**: "pr" or "issue"
- **flow_type**: One of: "last_response", "commit_summary", "review_response"
- **options**: Flow-specific options (commit hash, review text, etc.)

## Process

### 1. Validate Target

```bash
gh pr view <target> --json number,title  # for PRs
gh issue view <target> --json number,title  # for issues
```

If target not found, report error and exit.

### 2. Execute Flow

#### Flow: Last Response

Use skill `gitx:selecting-last-responses` to:

1. Present available responses from session
2. Let user select which to post
3. Return selected response as `$comment`

If skill returns no valid responses, report error.

#### Flow: Commit Summary

Use skill `gitx:generating-commit-summaries` with options:

- **mode**: "multi" (commits since hash) or "single" (single commit)
- **commit**: The commit hash reference
- **target**: PR/issue number for context

Skill returns formatted commit summary as `$comment`.

#### Flow: Review Response

**Step 1: Get Review Text**

If `options.review_text` provided, use it. Otherwise fetch latest review:

```bash
gh pr view <target> --json reviews \
  --jq '.reviews | map(select(.state != "APPROVED" and .state != "DISMISSED")) | sort_by(.submittedAt) | last'
```

**Step 2: Get Work Evidence**

If `options.commit` provided:

- Multi-commit mode: `git log --oneline <commit>..HEAD`
- Single-commit mode: `git show --stat <commit>`

Otherwise get recent commits: `git log --oneline -10`

**Step 3: Generate Response**

Create structured response:

```markdown
## Response to Review

[Address each review point]

## Work Done

### Summary
[Narrative of changes made]

### Changes
[Bullet list of commits]
```

Return generated response as `$comment`.

### 3. Validate Comment

Use skill `gitx:validating-comments` with `$comment`.

Handle validation results:

- **Pass**: Proceed to posting
- **Empty**: Return error to caller
- **Abort**: Exit without posting

### 4. Confirm and Post

Preview the comment via AskUserQuestion:

- Question: "Post this to [target_type] #[target]?"
- Options: ["Post", "Edit", "Cancel"]

Handle response:

- **Post**: Execute `gh pr comment` or `gh issue comment`
- **Edit**: Prompt for changes, return to validation
- **Cancel**: Exit without posting

### 5. Report Result

On success, return:

- Target number and title
- Comment preview (first 200 chars)
- Link to target

## Error Handling

| Error | Action |
|-------|--------|
| Target not found | Report and exit |
| No valid responses (last_response) | Report and exit |
| Invalid commit hash | Report and exit |
| gh command failure | Report error message |
| Validation failed | Return to caller |
