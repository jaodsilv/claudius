---
description: Updates PR title and description when changes have evolved. Use for refreshing outdated PR content.
argument-hint: "[PR_NUMBER]"
allowed-tools: Bash(git:*), Bash(gh:*), Task, Read, AskUserQuestion
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
- Main branch: !`ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && echo "${ref#refs/remotes/origin/}" || echo "main"`

Get PR details:

```bash
# If PR_NUMBER provided
gh pr view <PR_NUMBER> --json number,title,body,headRefName,baseRefName,url

# Otherwise get PR for current branch
gh pr view --json number,title,body,headRefName,baseRefName,url
```

## Pre-flight Checks

### Check PR exists

If no PR found:

- Report: "No PR found for this branch"
- Suggest: Use `/gitx:pr` to create one first
- Exit

### Store current state

Save for comparison:

- Current title
- Current body
- PR number
- PR URL

## Phase 1: Change Analysis

Launch change analyzer to understand all commits:

```text
Task (gitx:change-analyzer):
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
Task (gitx:description-generator):
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
