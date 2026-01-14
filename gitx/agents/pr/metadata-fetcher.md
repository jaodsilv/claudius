---
name: metadata-fetcher
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

Inputs can come as arguments, XML, or yaml or mixed between arguments and XML

### Values

- pr: PR number
- branch: PR branch
- worktree: PR worktree, it may come in any of the following formats:
  - absolute path with drive letter and backslashes: D:\src\claudius\skills-best-practices\
  - absolute path with drive letter and forward slashes: D:/src/claudius/skills-best-practices/
  - Bash style absolute path: /d/src/claudius/skills-best-practices/
  - relative path with forward slashes: ../skills-best-practices/
  - relative path with backslashes: ..\skills-best-practices\

If worktree is provided, regardless of the format, convert it to a Bash style absolute path.

### Examples

Arguments:

```text
--pr 64 --branch main --worktree D:/src/claudius/skills-best-practices/
```

XML:

```xml
<pr>64</pr>
<branch>main</branch>
<worktree>/d/src/claudius/skills-best-practices/</worktree>
```

YAML:

```yaml
pr: 64
branch: main
worktree: D:\src\claudius\skills-best-practices\
```

Mixed:

```markdown
--pr 64 --branch main

<worktree>D:/src/claudius/skills-best-practices/</worktree>
```

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

If worktree is found per instructions below, regardless of the original format of the path, convert it to Bash style absolute path, e.g., `D:/src/claudius/skills-best-practices/` -> `/d/src/claudius/skills-best-practices/` or `..\skills-best-practices\` -> `/d/src/claudius/skills-best-practices/`.

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

If there is no worktree for the branch:

- Report: "No worktree found for the PR branch"
- AskUserQuestion: "Should I create a worktree for the PR branch?"
- If yes, run the following slash commands using the Skill tool:

```markdown
/gitx:worktree $branch
```

- If no, Exit

### Phase 4: Get PR Description, checks, and latest comment

Run the following command using the Bash tool:

```bash
gh pr view $pr --json body,statusCheckRollup,comments,title,author,baseRefName --jq '{author: .author.login, title: .title, description: .body, base: .baseRefName, latestComment: (.comments?[-1] | {nodeid: .id, author: .author.login, timestamp: .createdAt, body: .body})}'
```

And set the output of that command to the `$metadata` variable.

### Phase 5: Get Non-resolved reviews

Run the following commands using the Bash tool:

```bash
gh repo view --json name,owner --jq '{owner: .owner.login, name: .name}'
```

And set the output of that command to the `$repo` variable.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviews(first: 100) {
        nodes {
          id
          body
          submittedAt
          isMinimized
        }
      }
    }
  }
}' -f owner=$repo.owner -f repo=$repo.name -F number=$pr   | jq '.data.repository.pullRequest.reviews.nodes[] | select(.isMinimized == false) | {nodeid: .id, body: .body, timestamp: .submittedAt}'
```

And set the output of that command to the `$latestReviews` variable.

### Phase 6: Get Review Round information

If the `$latestReviews` variable is empty:

- Set `$reviewCount` to 0

If the `$latestReviews` variable is not empty:

Check if the `$latestReviews[-1].body` variable contains the string "Round X" or similar where X is a number, and set `$reviewCount` to that number. Look only in the first 5 lines of the review body.

If this information is not available run the command with the Bash tool:

```bash
gh pr view $pr --json reviews --jq '.[] | length'
```

And set the output of that command to the `$reviewCount` variable.

### Phase 7: Get Turn information

If checks has any entry with conclusion different from "SUCCESS", "CANCELLED", "SKIPPED", or "" (empty), or have a status different from "COMPLETED":

- Set `$turn` to "CI-REVIEW"

If the `$latestReviews` variable is empty:

- Set `$turn` to "REVIEW"

Else if the `$latestComment` variable is empty:

- Set `$turn` to "RESPONSE"

Else:

- Compare the `$latestReviews[-1].timestamp` variable with the `$latestComment.timestamp` variable

- If the `$latestReviews[-1].timestamp` variable is greater than the `$latestComment.timestamp` variable set `$turn` to "RESPONSE"

- Else set `$turn` to "REVIEW"

### Phase 8: Get Latest Commit

Using the Bash tool run:

```bash
git -C $worktree log HEAD --max-count 1 --format="%H"
```

And set the output of that command to the `$latestCommit` variable.

### Phase 9: Get CI Status

Using the Bash tool run:

```bash
gh run list -b $branch --json headSha,conclusion,databaseId,name,status,url,workflowName --jq '.[] | select(.headSha == "$latestCommit")'
```

And set the output of that command to the `$ciStatus` variable.

### Phase 10: Output Metadata

Output using the following format:

```json
{
  "pr": $pr,
  "author": $metadata.author,
  "branch": $branch,
  "worktree": $worktree,
  "title": $metadata.title,
  "description": $metadata.description,
  "base": $metadata.base,
  "latestReviews": $latestReviews,
  "ciStatus": $ciStatus,
  "latestComment": $metadata.latestComment,
  "reviewCount": $reviewCount,
  "turn": $turn,
  "latestCommit": $latestCommit
}
```
