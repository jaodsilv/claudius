---
name: ci-status-checker
description: Checks CI status and provides feedback when needed.
argument-hint: "[--pr <pr>] [--worktree <worktree>] [--branch <branch>]"
allowed-tools: Bash(gh:*), Bash(git:*), Read, Task, TodoWrite, Write, AskUserQuestion, Skill, Grep, Glob
model: opus
---

# CI Status Checker

Checks CI status and provides feedback when needed.

## Parse Input

From the input, extract:

- Worktree (optional): The worktree where the code is located, set the `$worktree` variable to the worktree path if provided, empty string if not provided
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

```text
TodoWrite:
1. [ ] Gather PR context
2. [ ] Waiting All CI Checks to finish
3. [ ] Check CI failures exist
4. [ ] Analyze CI failures
```

## Phase 1: Gather Context

Mark "Gather PR context" as in_progress.

### Determine Worktree

If `$worktree` is empty, set it to the current directory (`.`).

### Ensure Metadata Exists

Use `gitx:managing-pr-metadata` skill to ensure metadata exists at `$worktree`.

If the skill indicates `needs_fetch`:

1. Run Task(gitx:pr:metadata-fetcher) with worktree
2. Retry ensure

### Read PR Metadata

Use the Read tool to read the PR metadata file at `$worktree/.thoughts/pr/metadata.yaml`.

If the file does not exist or has `noPr: true` or `error: true`:

- Report: "No PR metadata found. Use `/gitx:pr` to create a PR."
- Exit

Parse the YAML file and extract:

- Set the `$pr` variable to `pr`
- Set the `$branch` variable to `branch`
- Set the `$worktree` variable to `worktree`
- Set the `$ciStatus` variable to `ciStatus`
- Set the `$latestCommit` variable to `latestCommit`

Mark "Gather PR context" as completed.

## Phase 2: Wait for CI to finish

Mark "Waiting All CI Checks to finish" as in_progress.

If the `$cistatus` variable has ALL checks with a "status" equals to "completed", then mark "Waiting All CI Checks to finish" as completed and skip to Phase 3.

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

Use the Task tool to run the `gitx:address-review:ci-failure-analyzer` agent with the following prompt:

```text
PR Number: [number]
worktree: [worktree]
Branch: [branch]
Attempt Number: [attempt-number]

CI Failures:

<ci_failures>
[CI_FAILURES]
</ci_failures>

Output to .thoughts/checks/analysis.md
```

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

Use AskUserQuestion:

- "Orchestrated analysis encountered an issue. Continue manually?"
- Options:
  1. "Yes, proceed manually" - Use original non-orchestrated flow
  2. "Retry orchestration" - Try again
  3. "Cancel" - Exit

For manual mode, follow original address-ci logic without agents.
