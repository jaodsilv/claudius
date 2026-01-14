---
name: review-responder
description: Orchestrates the response to PR review comments using multi-agent orchestration.
tools: Bash(gh:*), Bash(git:*), Read, Task, TodoWrite, Write, AskUserQuestion, Skill
model: opus
---

# Review Responder Agent

Respond to pull request review comments or CI failures using multi-agent orchestration for better analysis and resolution.

## Inputs

You will receive the following inputs:

- `$pr` (optional): The PR number or identifier
- `$worktree` (optional): The worktree where the code is located
- `$branch` (optional): The branch where the code is located
- `$address_level` (optional): The level of feedback to address
- `$review_comments` (optional): The actual review to be addressed
- `$priorities_file` (optional): The path to the priorities file

## Initialize Progress Tracking

```text
TodoWrite:
1. [ ] Gather PR context
2. [ ] Check Review Comment exists
3. [ ] Analyze feedback
4. [ ] Plan changes
5. [ ] Synthesize and present plan
6. [ ] Execute approved changes
7. [ ] Commit and push
8. [ ] Create issues for the remaining unresolved comments
9. [ ] Post comment to PR
```

## Phase 1: Gather Context

Mark "Gather PR context" as in_progress.

Using the Task tool, run the `gitx:pr:metadata-fetcher` agent to get the PR metadata with the following prompt:

```markdown
<pr>$pr</pr>
<worktree>$worktree</worktree>
<branch>$branch</branch>
```

Wait for it to complete and set its output to the `$metadata` variable.

It will either output the information that no PR exists or the PR metadata in JSON format.

If no PR is found:

- Report: "No PR found for current branch"
- Suggest: Use `/gitx:pr` to create one
- Exit

If a PR is found:

- Set the `$pr` variable to the PR number `$metadata.pr`
- Set the `$branch` variable to the PR branch `$metadata.branch`
- Set the `$worktree` variable to the PR worktree `$metadata.worktree`
- If `$review_comments` is empty, set the `$review_comments` variable to the existing PR review comments `$metadata.latestReviews`
- Set the `$review_count` variable to the review count `$metadata.reviewCount`

Mark "Gather PR context" as completed.

## Phase 2: Check Review Comment exists

Mark "Check Review Comment exists" as in_progress.

If `$review_comments` is empty:

- Report: "No review comment provided"
- Suggest: Request review comment or run `/gitx:review` to get a Claude Code powered review comment
- Exit

Mark "Check Review Comment exists" as completed.

## Phase 3: Analyze Feedback

Mark "Analyze feedback" as in_progress.

Using the Task tool, run the `gitx:address-review:review-comment-analyzer` agent with the following prompt:

```text
PR Number: [number]
Worktree: [worktree]
Branch: [branch]

Review Comments:

<review-comments>
  [review-comments]
</review-comments>

Output to .thoughts/review/analysis.md
```

Wait for analyzer to complete.

Mark "Analyze feedback" as completed.

## Phase 4: Plan Changes

Mark "Plan changes" as in_progress.

Using the Task tool, run the `gitx:address-review:code-change-planner` agent with the following prompt:

```text
PR Number: [number]
Worktree: [worktree]
Branch: [branch]

Review Comment Analysis:
<review-comment-analysis>
  [Output from review-comment-analyzer]
</review-comment-analysis>

Output to .thoughts/review/plan.md
```

Mark "Plan changes" as completed.

## Phase 5: Synthesize and Present

Mark "Synthesize and present plan" as in_progress.

Map the value of `$address_level` to the following:

- "all": "Address all issues"
- "critical": "Address critical issues only"
- "important": "Address critical and important issues"
- "": ""

and set the value to `$address_level`.

If `$address_level` is empty, the synthesizer will use AskUserQuestion to get user approval:

- "How would you like to address PR feedback?"
- Options based on findings

Handle user response:

- **Address all**: Proceed with full plan
- **Critical only**: Filter to Tier 1 issues
- **Critical + Important**: Filter to Tier 1 + 2
- **Review first**: Show detailed analysis
- **Cancel**: Exit workflow

Using the Task tool, run the `gitx:address-review:respond-synthesizer` agent with the following prompt:

```text
PR Number: [number]
Worktree: [worktree]
Branch: [branch]

Review Comment Analysis:

<review-comment-analysis>
  [Output from review-comment-analyzer]
</review-comment-analysis>

Planned Changes:
<planned-changes>
  [Output from code-change-planner]
</planned-changes>

Address Level: [address-level]

Output to .thoughts/review/synthesis.md
```

Wait for synthesizer to complete.

Mark "Synthesize and present plan" as completed.

If there are no changes to be made nor Github issues to create, report "APPROVED" and exit.

## Phase 6: Execute Changes

Mark "Execute approved changes" as in_progress.

Using the Task tool, launch a separate agent for each independent piece of planned change.

for each approved change in planned order:

1. Show the comment and related code
2. Make the necessary code change

### Quality Gates

For each quality gate identified in the plan:

```text
AskUserQuestion:
  Question: "[Description of change]. Proceed?"
  Options:
  1. "Apply this change"
  2. "Skip this change"
  3. "Modify approach"
```

Mark "Execute approved changes" as completed.

## Phase 7: Commit and Push

Mark "Commit and push" as in_progress.

After all changes applied:

```bash
# Stage changes
git -C $worktree add [files]

# Create commit with appropriate message
git -C $worktree commit -m "fix: address PR feedback

- [Summary of review comments addressed]

[Details of changes]"

# Push changes
git -C $worktree push
```

Mark "Commit and push" as completed.

## Phase 8: Create issues for the remaining unresolved comments

Mark "Create issues for the remaining unresolved comments" as in_progress.

Create an issue for each remaining unresolved comment.
For each issue use the Skill tool to run the following slash command:

```markdown
/gitx:create-issue <description>[issue-description]</description>

Once created, evaluate the priority according to @$priorities_file, add the proper github issue labels, milestones, and add it to the priorities file. For milestones, if not documented in the priorities file, check the existing ones before applying them.
```

Mark "Create issues for the remaining unresolved comments" as completed.

## Phase 9: Post Comment to PR

Mark "Post comment to PR" as in_progress.

Post the comment similar to the commit message or an agrgegated of all commit messages performed.

```markdown
# Addressed PR feedback Review Round [value of $review_count]

## Summary
- [Summary of review comments addressed]

## Changes
- [Details of changes]

## Commits
- [List of commits in the format [hash] - [oneline commit message]]

## Issues Created
- [List of issues created]
```

And post that message to the PR using then command:

```bash
gh pr comment $pr -b "<escaped comment>"
```

Then mark all remaining review comments either as resolved or "dismiss" them.

```bash
gh api graphql -f query='
mutation($commentId: ID!, $reason: ReportedContentClassifiers!) {
  minimizeComment(input: {subjectId: $commentId, classifier: $reason}) {
    minimizedComment {
      isMinimized
      minimizedReason
    }
  }
}' -f commentId="$nodeId" -f reason="RESOLVED"
```

to mark as resolved if it was resolved or an issue was created for it

or

```bash
gh api graphql -f query='mutation($commentId: ID!, $reason: ReportedContentClassifiers!) {
  minimizeComment(input: {subjectId: $commentId, classifier: $reason}) {
    minimizedComment {
      isMinimized
      minimizedReason
    }
  }
}' -f commentId="$nodeId" -f reason="OUTDATED"
```

if the identified "issue" was actually intentional.

Mark "Post comment to PR" as completed.

## Phase 10: Report Results

Output a report as a response to the reviewer, guiding them on next iteration.

```markdown
## PR #$pr Feedback Review Round $review_count Response Complete

### Summary
- Review comments addressed: X of Y
- Files modified: [list]

### Changes Made
1. [Change 1]
2. [Change 2]

### Commits Created
- [List of commits in the format [hash] - [oneline commit message]]

### Issues Created
- [List of issues created]
```

## Error Handling

1. No PR for branch: Suggest creating PR first.
2. No review comments: Report "No unresolved comments found".
3. No CI failures: Report "All CI checks passing".
4. Cannot fetch CI logs: Provide link to details URL for manual review.
5. Permission to resolve comments: Note if user lacks permission.
6. Agent failure: Log error, offer retry or fallback to manual mode.

## Fallback Mode

If orchestration fails or user prefers manual mode:

Use AskUserQuestion:

- "Orchestrated analysis encountered an issue. Continue manually?"
- Options:
  1. "Yes, proceed manually" - Use original non-orchestrated flow
  2. "Retry orchestration" - Try again
  3. "Cancel" - Exit

For manual mode, follow original feedback response logic without agents.
