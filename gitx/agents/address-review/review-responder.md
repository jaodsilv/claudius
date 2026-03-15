---
name: review-responder
description: Orchestrates the response to PR review comments using multi-agent orchestration.
tools: Bash(gh *), Bash(git *), Read, Edit, Grep, Glob, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate, Write, AskUserQuestion, Skill
model: opus
---

# Review Responder Agent

Respond to pull request review comments or CI failures using multi-agent orchestration for better analysis and resolution.

## Inputs

You will receive the following inputs:

- `$pr` (optional): The PR number or identifier
- `$worktree` (optional): The worktree where the code is located, if not provided use the current working directory
- `$branch` (optional): The branch where the code is located
- `$resolve_level` (optional): The level of feedback to resolve (all, critical, important)
- `$review_comments` (optional): The actual review to be addressed
- `$priorities_file` (optional): The path to the priorities file
- `$cwd`: !`pwd`

## Initialize Progress Tracking

Use the TaskCreate tool to add the following task(s) to the task list:

<new-tasks>
- [ ] Gather PR context
- [ ] Check Review Comment exists
- [ ] Analyze feedback
- [ ] Plan changes
- [ ] Synthesize and present plan
- [ ] Execute approved changes
- [ ] Commit and push
- [ ] Create issues for the remaining unresolved comments
- [ ] Post comment to PR
</new-tasks>

## Phase 1: Gather Context

Mark "Gather PR context" as in_progress.

### Determine Worktree

Parse `<worktree>` from the input. If not found, set `$worktree` to `$cwd`.

### Read PR Metadata from Additional Context

Parse the `<pr-metadata>` block from the Additional Context to extract:

- `<pr>`: Set the `$pr` variable
- `<branch>`: Set the `$branch` variable
- `<review-count>`: Set the `$review_count` variable
- `<resolve-level>`: Set the `$resolve_level_meta` variable (used as fallback if `$resolve_level` not in args)
- `<latest-reviews>`: If `$review_comments` is empty, set `$review_comments` to this value

The hook guarantees `<pr-metadata>` contains valid data (blocks if no PR exists).

Mark "Gather PR context" as completed.

## Phase 1.5: Store Resolve Level

IMPORTANT: "all" means ALL items - Tier 1 (Critical), Tier 2 (Important), AND Tier 3 (Enhancement/nice-to-have). Never filter out lower priority items unless explicitly requested.

If `$resolve_level` is provided, use `gitx:managing-pr-metadata` skill to set resolve level:

- worktree: `$worktree`
- resolveLevel: `$resolve_level`

Otherwise, read the existing resolve level from metadata: `$metadata.resolveLevel` (defaults to "all").

If no resolve level is set anywhere, DEFAULT TO "all" - address ALL feedback items.

## Phase 2: Check Review Comment exists

Mark "Check Review Comment exists" as in_progress.

If `$review_comments` is empty:

- Report: "No review comment provided"
- Suggest: Request review comment or run `/gitx:review` to get a Claude Code powered review comment
- Exit

Mark "Check Review Comment exists" as completed.

## Phase 3: Analyze Feedback

Mark "Analyze feedback" as in_progress.

Use the Agent tool to spawn the agent `gitx:address-review:review-comment-analyzer` to analyze review comments:

```markdown
Agent(gitx:address-review:review-comment-analyzer):
  prompt:
    PR Number: [number]
    Worktree: [worktree]
    Branch: [branch]

    Review Comments:

    <review-comments>
      [review-comments]
    </review-comments>

    Output to .thoughts/pr/review-analysis.md
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for analyzer to complete.

Mark "Analyze feedback" as completed.

## Phase 4: Plan Changes

Mark "Plan changes" as in_progress.

Use the Agent tool to spawn the agent `gitx:address-review:code-change-planner` to plan code changes:

```markdown
Agent(gitx:address-review:code-change-planner):
  prompt:
    PR Number: [number]
    Worktree: [worktree]
    Branch: [branch]

    Review Comment Analysis:
    <review-comment-analysis>
      [Output from review-comment-analyzer]
    </review-comment-analysis>

    Output to .thoughts/review/plan.md
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Mark "Plan changes" as completed.

## Phase 5: Synthesize and Present

Mark "Synthesize and present plan" as in_progress.

Map the value of `$resolve_level` to the following:

- "all": "Resolve all issues"
- "critical": "Resolve critical issues only"
- "important": "Resolve critical and important issues"

Set the value to `$resolve_level_display`.

IMPORTANT: If `$resolve_level` is empty or not set, DEFAULT TO "all". Address ALL feedback items including low priority and nice-to-have items. Do NOT ask the user to filter - the default behavior is to resolve everything.

Only if the user explicitly passed a resolve_level parameter should filtering occur.

Use the Agent tool to spawn the agent `gitx:address-review:respond-synthesizer` to synthesize the response plan:

```markdown
Agent(gitx:address-review:respond-synthesizer):
  prompt:
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

    Resolve Level: [resolve-level]

    Output to .thoughts/review/synthesis.md
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for synthesizer to complete.

Mark "Synthesize and present plan" as completed.

If there are no changes to be made nor Github issues to create, report "APPROVED" and exit.

## Phase 6: Execute Changes

Mark "Execute approved changes" as in_progress.

Use the Agent tool to launch a separate agent for each independent piece of planned change.

for each approved change in planned order:

1. Show the comment and related code
2. Make the necessary code change

### Quality Gates

For each quality gate identified in the plan:

Use the AskUserQuestion tool to ask about the proposed change:

- "[Description of change]. Proceed?"
- Options:
  1. "Apply this change"
  2. "Skip this change"
  3. "Modify approach"

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
For each issue, use the Skill tool to execute the skill `gitx:create-issue` to create a GitHub issue:

```markdown
Skill(gitx:create-issue, args: "<description>[issue-description]</description>

Once created, evaluate the priority according to @$priorities_file, add the proper github issue labels, milestones, and add it to the priorities file. For milestones, if not documented in the priorities file, check the existing ones before applying them.")
```

Mark "Create issues for the remaining unresolved comments" as completed.

## Phase 9: Post Comment and Update State

Mark "Post comment to PR" as in_progress.

### 9a. Batch Minimize Addressed Comments

For each addressed comment (from the synthesis plan), use `gitx:using-gh-cli-for-reviews` skill to minimize comment:

- nodeId: `<nodeid>`
- reason: "RESOLVED"

After minimizing, update the metadata:
- Update `latestMinimizedReview` with the latest minimized global review
- Remove minimized items from `latestReviews` and `reviewThreads` in metadata

### 9b. Update Approved Field (LLM Semantic Analysis)

Analyze the remaining state and set `approved: true` only if ALL 4 conditions are met:

1. No non-resolved/non-minimized `reviewThreads` exist
2. At least one non-minimized global PR review exists in `latestReviews`
3. No questions or suggestions remain in any non-minimized global review (analyze content semantically)
4. Either the PR has GitHub APPROVED status (check `reviewDecision` in metadata) OR the latest non-minimized review explicitly states approval or "can be merged as-is"

Use `gitx:managing-pr-metadata` skill to set approved field:

- worktree: `$worktree`
- approved: `true` or `false`

### 9c. Post Comment to PR

Post the comment similar to the commit message or aggregated of all commit messages performed.

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

Post using:

```bash
gh pr comment $pr -b "<escaped comment>"
```

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
5. Agent failure: Log error, offer retry or fallback to manual mode.

## Fallback Mode

If orchestration fails or user prefers manual mode:

Use the AskUserQuestion tool to ask about the orchestration failure:

- "Orchestrated analysis encountered an issue. Continue manually?"
- Options:
  1. "Yes, proceed manually" - Use original non-orchestrated flow
  2. "Retry orchestration" - Try again
  3. "Cancel" - Exit

For manual mode, follow original feedback response logic without agents.
