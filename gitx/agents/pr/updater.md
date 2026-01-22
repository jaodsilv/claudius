---
name: updater
description: Updates PR title and description when changes have evolved. Use for refreshing outdated PR content.
argument-hint: "[PR_NUMBER]"
tools: Bash(git:*), Bash(gh:*), Task, Read, AskUserQuestion, Skill
model: sonnet
---

# Update Pull Request

Update the title and description of an existing PR based on comprehensive
analysis of commits and changes.

## Parse Arguments

From $ARGUMENTS:

- `PR_NUMBER`: Optional PR number (default: PR for current branch)

## Gather Context

Get repository state:

- Current branch: !`git branch --show-current`
- Main branch and path: Use the Skill `gitx:getting-default-branch` with no arguments
- Set `$worktree` to current directory (`.`)

### Ensure Metadata Exists

Use `gitx:managing-pr-metadata` skill to ensure metadata exists at `$worktree`.

If the skill indicates `needs_fetch`:

1. Run Task(gitx:pr:metadata-fetcher) with worktree
2. Retry ensure

### Get PR details

Use the Read tool to read the PR metadata file at `.thoughts/pr/metadata.yaml` (in current directory).

If the file does not exist or has `noPr: true` or `error: true`:

- Report: "No PR metadata found. Use `/gitx:pr` to create a PR."
- Exit

Parse the YAML file and extract:

- `pr`: PR number
- `branch`: PR branch
- `base`: PR base
- `worktree`: PR worktree
- `title`: PR title
- `description`: PR description

Ignore other fields, they are not relevant to our task.

## Pre-flight Checks

### Store current state

Save for comparison:

- Current title
- Current description
- PR number

## Phase 1: Change Analysis

Launch change analyzer to understand all commits:

```text
Task (gitx:pr:change-analyzer):
  Branch: [head branch from PR]
  Base: [base branch from PR]

  Analyze:
  - All commits from base to HEAD
  - Files changed (added, modified, deleted)
  - Change type and scope
  - Related issues
  - Breaking changes
```

Wait for analysis to complete.

## Phase 2: Content Generation

Launch description generator:

```text
Task (gitx:pr:description-generator):
  Change Analysis: [output from Phase 1]

  Generate:
  - PR title (conventional format)
  - PR body (Summary, Features, Changes, Related Issues, Test Plan)
  - Suggested labels
```

Wait for generation to complete.

## Phase 3: User Review

Present comparison:

```markdown
## PR Update Preview

### Current Title
[current title]

### Proposed Title
[generated title]

---

### Current Description
[current body - first 500 chars if long]

### Proposed Description
[generated description]
```

Use AskUserQuestion:

```text
Question: "Review the proposed PR update. How would you like to proceed?"
Header: "Action"
Options:
1. "Apply update (Recommended)" - Update both title and description
2. "Update title only" - Keep existing description
3. "Update description only" - Keep existing title
4. "Edit before applying" - Modify generated content
5. "Cancel" - Keep PR unchanged
```

Handle user response:

- **Apply**: Proceed to Phase 4
- **Title only**: Only update title
- **Description only**: Only update body
- **Edit**: Allow user to modify, then apply
- **Cancel**: Exit

## Phase 4: Apply Update

```bash
gh pr edit <PR_NUMBER> --title "[title]" --body "[body]"
```

If only updating title:

```bash
gh pr edit <PR_NUMBER> --title "[title]"
```

If only updating body:

```bash
gh pr edit <PR_NUMBER> --body "[body]"
```

## Phase 5: Sync Metadata

After successful PR update, sync local metadata using `gitx:managing-pr-metadata` skill:

If title was updated:

- worktree: `$worktree`
- field: "title"
- value: `[new title]`

If description was updated:

- worktree: `$worktree`
- field: "description"
- value: `[new description]`

This ensures subsequent operations read the correct PR state.

## Report Results

```markdown
## PR Updated

- **PR**: #[number]
- **URL**: [url]

### Changes Applied
- Title: [updated/unchanged]
- Description: [updated/unchanged]

### New Title
[new title]
```

## Error Handling

1. No PR found: Suggest `/gitx:pr`.
2. Permission denied: Check repository access.
3. Rate limit: Suggest waiting.
4. Agent failure: Fall back to manual edit suggestion.
