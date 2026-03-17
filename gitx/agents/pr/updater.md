---
name: updater
description: Updates PR title and description when changes have evolved. Use for refreshing outdated PR content.
argument-hint: "[PR_NUMBER]"
tools: Bash(git *), Bash(gh *), Agent, Read, AskUserQuestion, Skill
model: sonnet
---

# Update Pull Request

Update the title and description of an existing PR based on comprehensive
analysis of commits and changes.

## Input

From the prompt:

- `<worktree>`: Path to the worktree — store as `$worktree`
- Remaining text: optional PR number — store as `$pr_number`

Hook-injected (via `inject-pr-metadata.sh`):

- `<pr-metadata>`: PR metadata XML block containing `<pr>`, `<branch>`, `<base>`, `<title>`, `<description>`

## Parse Arguments

From $ARGUMENTS:

- `PR_NUMBER`: Optional PR number (default: PR for current branch)

## Gather Context

Get repository state:

- Current branch: !`git branch --show-current`
- Main branch and path: Use the Skill tool to execute the skill `gitx:getting-default-branch`:

  ```markdown
  Skill(gitx:getting-default-branch)
  ```

### Determine Worktree

Parse `<worktree>` from the input. Set `$worktree` to its value.

### Read PR Metadata from Additional Context

Parse the `<pr-metadata>` block from the Additional Context to extract:

- `<pr>`: Set the `$pr` variable (PR number)
- `<branch>`: Set the `$branch` variable
- `<base>`: Set the `$base` variable
- `<title>`: Set the `$title` variable
- `<description>`: Set the `$description` variable

The hook guarantees `<pr-metadata>` contains valid data (blocks if no PR exists).

## Pre-flight Checks

### Store current state

Save for comparison:

- Current title
- Current description
- PR number

## Phase 1: Change Analysis

Use the Agent tool to spawn the agent `gitx:pr:change-analyzer` to understand all commits:

```markdown
Agent(gitx:pr:change-analyzer):
  prompt:
    Branch: [head branch from PR]
    Base: [base branch from PR]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for analysis to complete.

## Phase 2: Content Generation

Use the Agent tool to spawn the agent `gitx:pr:description-generator` to generate updated content:

```markdown
Agent(gitx:pr:description-generator):
  prompt: <change-analysis>[output from Phase 1]</change-analysis>
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

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

Use the AskUserQuestion tool to ask how to proceed with the PR update:

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

After successful PR update, use the Skill tool to load the skill `gitx:managing-pr-metadata` to sync local metadata:

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
