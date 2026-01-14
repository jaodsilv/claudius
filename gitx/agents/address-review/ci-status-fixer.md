---
name: ci-status-fixer
description: Fixes CI failures when feedback needs addressing. Use for iterating on pull request feedback.
argument-hint: "[--pr <pr>] [--worktree <worktree>] [--branch <branch>]"
allowed-tools: Bash(gh:*), Bash(git:*), Read, Task, TodoWrite, Write, AskUserQuestion, Skill
model: opus
---

# CI Status Fixer

Fixes CI failures when feedback needs addressing. Use for iterating on pull request feedback.

## Parse Input

From the input, extract:

- Failures Analysis (Required): The failures analysis to use, set the `$failuresAnalysis` variable to the failures analysis if provided, empty string if not provided
- Worktree (optional): The worktree where the code is located, set the `$worktree` variable to the worktree path if provided, empty string if not provided
- PR (optional): The PR to respond to, set the `$pr` variable to the PR number if provided, empty string if not provided
- Branch (optional): The branch where the code is located, set the `$branch` variable to the branch name if provided, empty string if not provided
- Address Level (optional): The address level to use, set the `$addressLevel` variable to the address level if provided, "all" if not provided
- Attempt Number (optional): The attempt number to use, set the `$attemptNumber` variable to the attempt number if provided, 1 if not provided

Input format is free, but needs to be clear:

```markdown
pr: $pr
worktree: $worktree
branch: $branch
address_level: $address_level

Failures Analysis: 

<failures_analysis>
$failures_analysis
</failures_analysis>
```

Prompt Examples:

Fix CI failures from specific PR:

```bash
--pr <pr>

```

Fix CI failures from specific branch:

```bash
--branch <branch>

```

Fix CI failures from specific PR and branch:

```bash
--pr <pr> --branch <branch>

```

Fix CI failures from specific worktree:

```bash
--worktree <worktree>

```

Fix CI failures from current branch:

```bash

```

Set the following variables:

- $pr: The PR number, empty if not provided
- $worktree: The worktree path, empty if not provided
- $branch: The branch name, empty if not provided

## Initialize Progress Tracking

```text
TodoWrite:
1. [ ] Gather PR context
2. [ ] Plan changes
3. [ ] Synthesize and present plan
4. [ ] Execute approved changes
5. [ ] Commit and push
6. [ ] Post comment to PR
```

## Phase 1: Gather Context

Mark "Gather PR context" as in_progress.

If none of the variables `$pr`, `$worktree` or `$branch` are empty, then skip to "Plan changes".

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

Mark "Gather PR context" as completed.

## Phase 2: Plan Changes

Mark "Plan changes" as in_progress.

Use the Task tool to run the `gitx:address-review:code-change-planner` agent with the following prompt:

```markdown
PR Number: $pr
worktree: $worktree
Branch: $branch

CI Failures Analysis:

<ci_failures_analysis>
$failures_analysis
</ci_failures_analysis>

Output to .thoughts/checks/plan.md
```

Mark "Plan changes" as completed.

## Phase 3: Synthesize and Present

Mark "Synthesize and present plan" as in_progress.

Use the Task tool to run the `gitx:address-review:respond-synthesizer` agent with the following prompt:

```markdown
PR Number: $pr
worktree: $worktree
Branch: $branch
Address Level: Address all issues

Plan:

<plan>
$plan
</plan>

Output to .thoughts/checks/action-plan.md
```

Mark "Synthesize and present plan" as completed.

## Phase 4: Execute Changes

Mark "Execute approved changes" as in_progress.

For each approved change in planned order, using the Task tool for each independent change:

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

## Phase 5: Commit and Push

Mark "Commit and push" as in_progress.

After all changes applied:

```bash
# Stage changes
git -C $worktree add $files

# Create commit with appropriate message
git -C $worktree commit -m "fix: address CI failures

- [Summary of CI fixes applied]

[Details of changes]"

# Push changes
git -C $worktree push
```

Mark "Commit and push" as completed.

## Phase 6: Output Report

Output a report:

```markdown
## PR CI Feedback Response Attempt $attemptNumber

### Summary
- CI failures fixed: Y of Z
- Files modified: [list]

### Changes Made
1. [Change 1]
2. [Change 2]

### Commits Created

- [hash1]: [message1]
- [hash2]: [message2]

### Next Steps

- Wait for reviewer re-review
```

If there is an instruction to write to a file, write the report to the file.

Output the report to the user/orchestrator.

## Error Handling

1. No PR for branch: Suggest creating PR first.
2. No CI failures: Report "All CI checks passing".
3. Cannot fetch CI logs: Provide link to details URL for manual review.
4. Permission to resolve comments: Note if user lacks permission.
5. Agent failure: Log error, offer retry or fallback to manual mode.

## Fallback Mode

If orchestration fails or user prefers manual mode:

Use AskUserQuestion:

- "Orchestrated analysis encountered an issue. Continue manually?"
- Options:
  1. "Yes, proceed manually" - Use original non-orchestrated flow
  2. "Retry orchestration" - Try again
  3. "Cancel" - Exit

For manual mode, follow original address-ci logic without agents.
