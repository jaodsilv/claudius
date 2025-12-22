---
description: Respond to PR review comments; use --ci for CI failures
argument-hint: "[--ci] [response-context]"
allowed-tools: Bash(gh:*), Bash(git:*), Read, AskUserQuestion
---

# Respond to PR Feedback

Respond to pull request review comments or CI failures. Requires explicit `--ci` flag for CI failures (default is review comments).

## Parse Arguments

From $ARGUMENTS, extract:
- `--ci`: Flag indicating this is a CI failure response (not a review)
- Response context (optional): Additional context about what to address

## Gather Context

Get PR information:
- Current branch: !`git branch --show-current`
- PR for branch: !`gh pr view --json number,url,title,state,reviewDecision 2>/dev/null`

If no PR found:
- Report: "No PR found for current branch"
- Suggest: Use `/gitx:pr` to create one

## Mode: Review Comments (default, no --ci flag)

### Get Review Comments

Fetch pending reviews and comments:
```bash
gh pr view --json reviews,comments --jq '.reviews[] | select(.state != "APPROVED") | {author: .author.login, state: .state, body: .body}'
gh pr view --json reviewThreads --jq '.reviewThreads[] | select(.isResolved == false)'
```

### Display Comments

Show unresolved comments:
- Author
- File and line (if applicable)
- Comment text
- Thread context

### Ask How to Respond

Use AskUserQuestion:
- "Found <count> unresolved review comments. How would you like to respond?"
- Options:
  1. "Address all comments" - Work through each comment
  2. "Address specific comment" - Choose which to handle
  3. "View comments in detail" - See full context first
  4. "Cancel" - Exit

### Address Comments

For each comment being addressed:
1. Show the comment and related code
2. Understand what change is requested
3. Make the necessary code change
4. After fixing, mark as resolved:
   ```bash
   gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<id>"}) { thread { isResolved } } }'
   ```

After addressing:
- Commit changes with message referencing the review
- Push changes
- Report what was addressed

## Mode: CI Failure (--ci flag)

### Get CI Status

Fetch CI check results:
```bash
gh pr checks --json name,status,conclusion,detailsUrl
```

### Identify Failures

Filter for failed checks:
- Status: completed
- Conclusion: failure or cancelled

### Display Failures

For each failed check:
- Check name
- Failure details URL
- If available, fetch failure output

### Ask How to Proceed

Use AskUserQuestion:
- "Found <count> failed CI checks. How would you like to proceed?"
- Options:
  1. "Investigate failures" - Analyze each failure
  2. "View failure logs" - Get detailed output
  3. "I know the issue" - Provide context and fix directly
  4. "Cancel" - Exit

### Fix CI Issues

Based on failure type:

**Test failures:**
- Fetch test output from CI
- Identify failing tests
- Analyze and fix the issue
- Run tests locally to verify

**Lint/Format failures:**
- Identify linting issues
- Apply fixes
- Verify locally

**Build failures:**
- Check build logs
- Fix compilation/build errors
- Verify build locally

After fixing:
- Commit with message describing the fix
- Push changes
- Wait for CI to re-run
- Report: "Changes pushed. CI checks will re-run."

## Report Results

After responding:
- Summary of changes made
- Commits created
- Comments resolved / CI fixes pushed
- Suggest: "Wait for CI to complete and reviews to be updated"

## Error Handling

- No PR for branch: Suggest creating PR first
- No review comments: Report "No unresolved comments found"
- No CI failures: Report "All CI checks passing"
- Cannot fetch CI logs: Provide link to details URL for manual review
- Permission to resolve comments: Note if user lacks permission
