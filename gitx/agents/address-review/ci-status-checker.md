---
name: ci-status-checker
description: "DEPRECATED: Replaced by gitx:ci:* multi-agent pipeline. Use /gitx:address-ci instead."
argument-hint: "[--pr <pr>] [--worktree <worktree>] [--branch <branch>]"
allowed-tools: Bash(gh *), Bash(git *), Read, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate, Write, AskUserQuestion, Skill, Grep, Glob
model: opus
---

# CI Status Checker

## Parse Input

From the input, extract:

- Worktree (optional): The worktree where the code is located,
  set the `$worktree` variable to the worktree path if provided, empty string if not provided
- PR (optional): The PR to respond to, set the `$pr` variable to the PR number if provided, empty string if not provided
- Branch (optional): The branch where the code is located, set the `$branch` variable to the branch name if provided, empty string if not provided
- Attempt Number (optional): The attempt number to use, set the `$attemptNumber` variable to the attempt number if provided, 1 if not provided

Input format is bash arguments:

```markdown
[--pr <pr>] [--worktree <worktree>] [--branch <branch>] [--attempt-number <attempt-number>]
```

Prompt Examples:

Check CI status from specific PR:

```bash
--pr <pr>

```

Check CI status from specific branch:

```bash
--branch <branch>

```

Check CI status from specific PR and branch:

```bash
--pr <pr> --branch <branch>

```

Check CI status from specific worktree:

```bash
--worktree <worktree>

```

Check CI status from current branch:

```bash

```

Set the following variables:

- $pr: The PR number, empty if not provided
- $worktree: The worktree path, empty if not provided
- $branch: The branch name, empty if not provided

## Initialize Progress Tracking

Use the TaskCreate tool to add the following task(s) to the task list:

<new-tasks>
- [ ] Gather PR context
- [ ] Waiting All CI Checks to finish
- [ ] Check CI failures exist
- [ ] Analyze CI failures
</new-tasks>

## Phase 1: Gather Context

Mark "Gather PR context" as in_progress.

### Determine Worktree

Parse `<worktree>` from the input. If not found, set `$worktree` to the current directory (`.`).

### Read PR Metadata from Additional Context

Parse the `<pr-metadata>` block from the Additional Context to extract:

- `<pr>`: Set the `$pr` variable
- `<branch>`: Set the `$branch` variable
- `<ci-status>`: Set the `$ciStatus` variable
- `<latest-commit>`: Set the `$latestCommit` variable

The hook guarantees `<pr-metadata>` contains valid data (blocks if no PR exists).

Mark "Gather PR context" as completed.

## Phase 2: Wait for CI to finish

Mark "Waiting All CI Checks to finish" as in_progress.

If the `$cistatus` variable has ALL checks with a "status" equals to "completed",
then mark "Waiting All CI Checks to finish" as completed and skip to Phase 3.

1. Wait 10 seconds with the following command using the Bash tool:

   ```bash
   sleep 10
   ```

2. Check again with the following command using the Bash tool:

   ```bash
   gh run list -b $branch --json headSha,status --jq '.[] | select(.headSha == "$latestCommit" and .status != "completed")'
   ```

3. Repeate this process of waiting and checking until the command above returns no results.

Once no results are found mark "Waiting All CI Checks to finish" as completed.

## Phase 3: Check CI failures exist

Mark "Check CI failures exist" as in_progress.

Check what feedback exists:

```bash
gh run list -b $branch --json headSha,conclusion,databaseId,name,url,workflowName --jq '.[] | select(.headSha == "$latestCommit" and .conclusion == "failure")'
```

If no CI failures exist:

- Mark all progress tracking items as completed
- Report: "No CI failures found"
- Exit

Output to .thoughts/checks/raw-failures.md

Mark "Check CI failures exist" as completed.

## Phase 4: Failure Analysis

Mark "Failure Analysis" as in_progress.

Use the Agent tool to spawn the agent `gitx:address-review:ci-failure-analyzer` to analyze CI failures:

```markdown
Agent(gitx:address-review:ci-failure-analyzer):
  prompt:
    <worktree>$worktree</worktree>
    <pr>$pr</pr>
    <branch>$branch</branch>
    <attempt-number>$attemptNumber</attempt-number>

    CI Failures:

    <ci_failures>
    [CI_FAILURES]
    </ci_failures>

    Output to <output-path>`.thoughts/checks/analysis.md`</output-path>
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for analyzer to complete.

Mark "Failure Analysis" as completed.

Return the result of the analyzer to the user/orchestrator.

## Error Handling

1. No PR for branch: Suggest creating PR first.
2. No CI failures: Report "All CI checks passing".
3. Cannot fetch CI logs: Provide link to details URL for manual review.
4. Agent failure: Log error, offer retry or fallback to manual mode.

## Fallback Mode

If orchestration fails or user prefers manual mode:

Use the AskUserQuestion tool to ask about the orchestration failure:

- "Orchestrated analysis encountered an issue. Continue manually?"
- Options:
  1. "Yes, proceed manually" - Use original non-orchestrated flow
  2. "Retry orchestration" - Try again
  3. "Cancel" - Exit

For manual mode, follow original address-ci logic without agents.
