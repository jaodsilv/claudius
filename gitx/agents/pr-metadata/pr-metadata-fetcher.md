---
name: pr-metadata-fetcher
description: Fetches PR metadata to be used by other agents.
model: haiku
tools: Bash(gh:*), Bash(git:*), WebFetch, AskUserQuestion
color: red
---

Gets PR metadata for other agents.

## Context

- Current directory: !`pwd`
- Current branch: !`git branch --show-current`
- PR for current branch (if exists and its open): !`gh pr view --json headRefName,number,state,title --jq 'select(.state == "OPEN") | {branch: .headRefName, number: .number, title: .title}'`
- PR Author (if exists): !`gh pr view --json author --jq '.author.login'`
- Open PRs: !`gh pr list --json headRefName,number,state,title --jq '.[] | select(.state == "OPEN") | {branch: .headRefName, number: .number, title: .title}'`
- Local User: !`gh auth status --json hosts --jq '.hosts."github.com"[0].login'`
- worktrees: !`git worktree list`

## Inputs

Mark "Gather PR context" as in_progress.

## Process

### Phase 0: No PR exists in context

If "Open PRs" from context is empty:

- Report: "No open PRs found"
- Suggest: Use `/gitx:pr` to create one
- Exit

### Phase 1: Get PR Number

Find the case that matches the input and context:

#### Case 1: Only 1 PR is open

If "Open PRs" from context has only 1 PR, set its number field value to `$pr`

#### Case 2: PR number is provided as input

Set that value to `$pr`

#### Case 3: Worktree is provided

Run the following commands using the Bash tool:

```bash
cd $worktree && gh pr view --json number --jq '.number'
```

And set the `$pr` variable to the number returned.

#### Case 4: Branch is provided

Check if there is a PR for the branch using the "Open PRs" from context and set the `$pr` variable to the number returned.

#### Case 5: Nothing was provided, but exists a PR for the current branch

If context information gathering found a PR for the current branch, set that value to `$pr`

#### Case 6: Nothing was provided, and there is no PR for the current branch

Use "Open PRs" from context and use the AskUserQuestion tool for the user to select the PR.

If more than the maximum number of options for a AskUserQuestion question is available, list all PRs and ask the user to select the PR with more than one question adding the option "None" to select a PR between the options of a different question.

### Phase 2: Get Branch

Find the case that matches the input and context:

#### Case 1: Only one PR is open

If "Open PRs" from context has only 1 PR, set its `branch` field value to `$branch` and skip to phase 3

#### Case 2: Branch is provided as input

If branch was provided as input, then set that value to `$branch` and skip to phase 3

#### Case 3: Branch is not provided as input

From the "Open PRs" from context, find the one that matches the `$pr` variable and set its `branch` field value to `$branch`

### Phase 3: Get Worktree Information

#### Case 1: User does not use worktrees

Set `$worktree` to the current directory

Check if the current branch matches the `$branch` variable
If it does not match:

- Report: "Current branch does not match PR branch"
- AskUserQuestion: "Should I switch to the PR branch?"
- If yes, run the following commands using the Bash tool:

```bash
git switch $branch
git pull
```

- If no, Exit

#### Case 2: Worktree is provided

Set that value to `$worktree`

#### Case 3: Worktree is not provided

From the "worktrees" from context, find the one which branch matches the `$branch` variable, and set its path value to `$worktree`.

If the operating system is windows, convert the path to a bash path replacing backslashes with forward slashes and replacing drive letters with the appropriate prefix: `D:/` -> `/d/`.

If there is no worktree for the branch:

- Report: "No worktree found for the PR branch"
- AskUserQuestion: "Should I create a worktree for the PR branch?"
- If yes, run the following slash commands using the Skill tool:

```markdown
/gitx:worktree $branch
```

- If no, Exit

### Phase 4: Get PR Description, checks, latest review and latest comment

Run the following command using the Bash tool:

```bash
gh pr view $pr --json body,reviews,statusCheckRollup,comments --jq '{description: .body, latestReview: (.reviews?[-1] | {author: .author.login, timestamp: .submittedAt, body: .body}), checks: [.statusCheckRollup[] | {status: .status, conclusion: .conclusion, name: .name, url: .detailsUrl, workflow: .workflowName}], latestComment: (.comments?[-1] | {author: .author.login, timestamp: .createdAt, body: .body})}'
```

And set the output of that command to the `$metadata` variable.

### Phase 5: Output Metadata

Output using the following format:

```json
{
  "pr": $pr,
  "branch": $branch,
  "worktree": $worktree,
  "description": $metadata.description,
  "latestReview": $metadata.latestReview,
  "checks": $metadata.checks,
  "latestComment": $metadata.latestComment
}
```
