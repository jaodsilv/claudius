---
description: Comments on a pull request when sharing status or responding. Use for PR discussion or posting summaries.
argument-hint: "[PR] [comment | -l | --last | -c <commit> | --commit <commit> | -sc <commit> | --single-commit <commit> | -r [\"text\"] | --review [\"text\"]]"
allowed-tools: Bash(gh pr:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git rev-parse:*), AskUserQuestion, Skill(gitx:validating-comments), Skill(gitx:selecting-last-responses), Skill(gitx:generating-commit-summaries)
---

# Comment on Pull Request

Add a comment to a GitHub pull request. If PR number is not provided, uses the PR for the current branch.

## Parse Arguments

From $ARGUMENTS, extract:

- PR number (optional): First numeric argument
- Comment text (optional): Remaining text after PR number (unless flags are used)
- `--last` or `-l` flag: If present, triggers last response flow
- `-c` or `--commit` flag with value: If present, triggers commit-since summary flow
- `-sc` or `--single-commit` flag with value: If present, triggers single-commit summary flow
- `-r` or `--review` flag with optional value: If present, triggers review response flow
  - If followed by quoted string: Use as the review text to respond to
  - If no value provided: Auto-fetch latest review from PR
  - Can be combined with `-c <commit>` or `-sc <commit>` to include commit evidence
  - **Parsing note**: Quoted string must immediately follow `-r`/`--review` flag

**Flag combination rules:**

- `-r` alone: Respond to latest review with general summary of work done
- `-r "text"`: Respond to specified review text with general summary
- `-r -c <commit>`: Respond to latest review with commits since `<commit>` as evidence
- `-r "text" -c <commit>`: Respond to specified review with commits since `<commit>`
- `-r -sc <commit>`: Respond to latest review with single commit as evidence
- `-r "text" -sc <commit>`: Respond to specified review with single commit as evidence
- `-r` cannot be combined with `--last` (exclusive flows)

**Usage examples:**

```bash
/comment-to-pr -r                         # Auto-fetch latest review, respond with recent work
/comment-to-pr -r "Please address concerns"  # Respond to specified review text
/comment-to-pr -r -c abc1234              # Respond with commits since abc1234 as evidence
/comment-to-pr 42 -r -sc def5678          # Respond to PR #42 with single commit evidence
```

## Infer PR Number

If no PR number provided:

1. Get current branch: !`git branch --show-current`
2. Find PR for branch: `gh pr view --json number,title`

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

### Auto-generated summaries

If "Summarize recent changes":

- Get commits since PR creation
- Get changed files summary
- Generate summary of recent work

### Commit-based summaries

If `-c <commit>` or `--commit <commit>` flag used:

- Use skill `gitx:generating-commit-summaries` with multi-commit mode
- Target: PR #\<number\>

If `-sc <commit>` or `--single-commit <commit>` flag used:

- Use skill `gitx:generating-commit-summaries` with single-commit mode
- Target: PR #\<number\>

### Review Response Flow

If `-r` or `--review` flag used:

#### Step 1: Get Review Text

**If review text provided in arguments:**

- Use the provided quoted string as `$review_text`

**If no review text provided (flag used alone):**

1. Fetch latest review from PR:

   ```bash
   # Filters for actionable reviews: PENDING, CHANGES_REQUESTED, COMMENTED
   gh pr view <number> --json reviews \
     --jq '.reviews
       | map(select(.state != "APPROVED" and .state != "DISMISSED"))
       | sort_by(.submittedAt)
       | last'
   ```

2. If review found:
   - Extract review body and author
   - Show: "Found latest review from @<author>"
   - Set `$review_text` to review body

3. If no pending reviews found:
   - Check for unresolved review comments (inline comments):

     ```bash
     gh pr view <number> --json reviewThreads \
       --jq '[.reviewThreads[] | select(.isResolved == false)] | last'
     ```

   - If found, use the last unresolved thread's comments
   - If no reviews or threads found:
     - Use AskUserQuestion: "No pending reviews found. What would you like to do?"
     - Header: "No Reviews"
     - Options:
       1. "Enter review text manually" - Prompt for review text
       2. "Cancel" - Abort operation

#### Step 2: Get Work Evidence

**If `-c <commit>` also provided:**

1. Validate commit hash exists: `git rev-parse --verify <commit>^{commit}`
2. Get all commits since that commit: `git log --oneline <commit>..HEAD`
3. Get changed files summary: `git diff --stat <commit>..HEAD`
4. Store in `$work_evidence` variable

**If `-sc <commit>` also provided:**

1. Validate commit hash exists: `git rev-parse --verify <commit>^{commit}`
2. Get commit details: `git show --stat --format="%s%n%n%b" <commit>`
3. Get the actual diff for the commit: `git show --no-stat <commit>`
4. Store in `$work_evidence` variable

**If neither `-c` nor `-sc` provided:**

1. Get recent commits on this branch (last 10):

   ```bash
   git log --oneline -10
   git diff --stat HEAD~10..HEAD
   ```

2. Store in `$work_evidence` variable (may be empty if no recent work)

#### Step 3: Generate Response

Generate a structured response addressing the review points:

**Output format:**

```markdown
## Response to Review

[Thoughtful response addressing each point raised in the review]

[If the review raised specific concerns, address them point by point]

## Work Done

### Summary

[Narrative paragraph summarizing what was done to address the review]

### Changes
[Bullet list of commits or changes made]
```

**If no `$work_evidence` available:**

```markdown
## Response to Review

[Thoughtful response addressing each point raised in the review]

---
*Note: This response is being posted before/without commit evidence. The work may be in progress or was addressed in conversation.*
```

**Response generation guidelines:**

1. Analyze the review text to identify:
   - Specific concerns or questions
   - Requested changes
   - Suggestions for improvement
2. For each identified point, provide:
   - Acknowledgment of the feedback
   - How it was addressed (if applicable)
   - Justification if not addressed (if applicable)
3. Be professional and constructive in tone
4. Reference specific commits when available

#### Step 4: Preview and Confirm

Use AskUserQuestion:

- Show preview: Full generated response
- Question: "Post this response to PR #<number>?"
- Header: "Confirm"
- Options:
  1. "✅ Post this response" - Proceed to validation
  2. "✏️ Edit response" - Allow modification based on feedback
  3. "❌ Cancel" - Abort posting

If "Edit response" selected:

- Use AskUserQuestion: "What would you like to change about the response?"
- Regenerate response based on user input
- Return to Step 4 preview (loop continues until user selects "Post" or "Cancel")

#### Step 5: Store and Proceed

Store generated response in `$comment` variable and proceed to "Validate Comment" section.

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

- Use skill `gitx:selecting-last-responses`
- Target: PR #\<number\>

## Validate Comment

Use skill `gitx:validating-comments` to validate `$comment` before posting.

If validation fails with empty comment, return to "Get Comment Text" section.

## Post Comment

Post the comment:

- `gh pr comment <number> --body "$comment"`

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
8. Invalid commit hash: Report "Commit '<hash>' not found in repository. Please verify the commit hash."
9. Commit not in history: Report "Commit '<hash>' exists but is not in current branch's history."
10. No reviews found (--review flag): Triggers when user selects "Cancel" in the AskUserQuestion after no
    reviews are found. Report "No pending reviews or unresolved review comments found for this PR."
    Suggest using --review with explicit text or a different comment option.
11. Review fetch failed (--review flag): Report the gh error and suggest checking PR access permissions.
12. Invalid flag combination: If `-r` is combined with `--last`, report "Cannot combine --review
    with --last flag. Use one or the other."
13. Empty review text: If review text is explicitly provided but empty (e.g., `--review ""`),
    report "Review text cannot be empty when using --review with quoted text."
