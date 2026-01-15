---

description: Responds to PR review comments or CI failures when feedback needs addressing. Use for iterating on pull request feedback.
argument-hint: "[--ci] [response-context]"
allowed-tools: Bash(gh:*), Bash(git:*), Read, Task, TodoWrite, Write, AskUserQuestion, Skill(gitx:classifying-issues-and-failures)
model: opus
---

# Respond to PR Feedback (Orchestrated)

Respond to pull request review comments or CI failures using multi-agent orchestration for better analysis and resolution.

## Parse Arguments

From $ARGUMENTS, extract:

- `--ci`: Flag indicating this is a CI failure response (not a review)
- Response context (optional): Additional context about what to address

## Initialize Progress Tracking

```text
TodoWrite:
1. [ ] Gather PR context
2. [ ] Analyze feedback (parallel)
3. [ ] Plan changes
4. [ ] Synthesize and present plan
5. [ ] Execute approved changes
6. [ ] Commit and push
```

## Phase 1: Gather Context

Mark "Gather PR context" as in_progress.

Get PR information:

- Current branch: !`git branch --show-current`
- PR for branch: !`gh pr view --json number,url,title,state,reviewDecision 2>/dev/null`

If no PR found:

- Report: "No PR found for current branch"
- Suggest: Use `/gitx:pr` to create one
- Exit

Mark "Gather PR context" as completed.

## Phase 2: Parallel Analysis

Mark "Analyze feedback (parallel)" as in_progress.

### Determine Analysis Mode

Check what feedback exists:

```bash
# Count review comments
REVIEW_COUNT=$(gh pr view --json reviewThreads --jq '[.reviewThreads[] | select(.isResolved == false)] | length')

# Count CI failures
CI_FAILURES=$(gh pr checks --json conclusion --jq '[.[] | select(.conclusion == "failure")] | length')
```

### Launch Analyzers

**If review comments exist AND (no --ci flag OR both exist)**:

```text
Task (gitx:respond:review-comment-analyzer):
  PR Number: [number]
  Analyze all unresolved review comments.
  Categorize by type and effort.
  Output to respond-analysis.md
```

**If CI failures exist AND --ci flag (OR both exist)**:

```text
Task (gitx:respond:ci-failure-analyzer):
  PR Number: [number]
  Analyze all CI check failures.
  Identify root causes and fixes.
  Output to respond-analysis.md
```

**If both exist, launch BOTH in parallel**.

Wait for all analyzers to complete.

Mark "Analyze feedback (parallel)" as completed.

## Phase 3: Plan Changes

Mark "Plan changes" as in_progress.

Launch planner with combined analysis:

```text
Task (gitx:respond:code-change-planner):
  PR Number: [number]

  Review Comment Analysis:
  [Output from review-comment-analyzer]

  CI Failure Analysis:
  [Output from ci-failure-analyzer]

  Create ordered execution plan with:
  - Change sequence
  - Dependencies
  - Quality gates
```

Mark "Plan changes" as completed.

## Phase 4: Synthesize and Present

Mark "Synthesize and present plan" as in_progress.

Launch synthesizer:

```text
Task (gitx:respond:respond-synthesizer):
  Combine all analysis results.
  Create tiered action plan.
  Detect conflicts.
  Present to user for approval.
```

The synthesizer will use AskUserQuestion to get user approval:

- "How would you like to address PR feedback?"
- Options based on findings

Handle user response:

- **Address all**: Proceed with full plan
- **Critical only**: Filter to Tier 1 issues
- **Critical + Important**: Filter to Tier 1 + 2
- **Review first**: Show detailed analysis
- **Cancel**: Exit workflow

Mark "Synthesize and present plan" as completed.

## Phase 5: Execute Changes

Mark "Execute approved changes" as in_progress.

For each approved change in planned order:

### For Review Comments

1. Show the comment and related code
2. Make the necessary code change
3. After fixing, mark as resolved:

   ```bash
   gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<id>"}) { thread { isResolved } } }'
   ```

### For CI Failures

**Test failures:**

- Apply fix from analysis
- Run tests locally to verify (detect project's test command from package.json, Makefile, etc.)

**Lint/Format failures:**

- Apply auto-fix using project's lint command with fix flag
- Verify locally

**Build failures:**

- Apply fix from analysis
- Verify build using project's build command

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

## Phase 6: Commit and Push

Mark "Commit and push" as in_progress.

After all changes applied:

```bash
# Stage changes
git add -A

# Create commit with appropriate message
git commit -m "fix: address PR feedback

- [Summary of review comments addressed]
- [Summary of CI fixes applied]

[Details of changes]"

# Push changes
git push
```

Mark "Commit and push" as completed.

## Report Results

After responding:

```markdown
## PR Feedback Response Complete

### Summary
- Review comments addressed: X of Y
- CI failures fixed: X of Y
- Files modified: [list]

### Changes Made
1. [Change 1]
2. [Change 2]

### Commits Created
- [hash]: [message]

### Next Steps
- Wait for CI to complete
- Wait for reviewer re-review
- Use `/gitx:respond` again if new feedback
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

For manual mode, follow original respond logic without agents.
