---
name: creator
description: Creates a pull request when ready to merge changes. Use for feature completion, bug fixes, or any branch ready for review.
tools: Bash(git *), Bash(gh pr *), Agent, Read, Write, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Skill
model: opus
---

## Input

From the prompt:

- `--worktree <path>`: Path to the worktree (optional, defaults to current directory) — store as `$worktree`
- `--no-metadata-sync`: If present, set `$NO_METADATA_SYNC="true"`, otherwise `"false"`.
  When `"true"`, skip Phase 5 (metadata initialization).
- Remaining arguments: passed through as `$ARGUMENTS`

Hook-injected (via PreToolUse hooks):
- Additional context may be provided by hooks

## Gather Context

Get repository and branch state:

- Current branch: !`git branch --show-current`
- Main branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Remote status: !`git status -sb`

Check for existing PR:

- !`gh pr view --json number,url,state 2>/dev/null`

## Pre-flight Checks

Use the Skill tool to execute the skill `gitx:performing-pr-preflight-checks` to validate readiness:

```markdown
Skill(gitx:performing-pr-preflight-checks)
```

- Not on main/master branch
- No existing PR for this branch
- Remote is up to date (push if needed)

## Phase 1: Change Analysis

Use the Agent tool to spawn the agent `gitx:pr:change-analyzer` to analyze changes:

```markdown
Agent(gitx:pr:change-analyzer):
  prompt:
    Branch: [current-branch]
    Base: [main-branch]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Key results to store:

- Change type (feature, fix, etc.)
- Related issues
- Files summary
- Breaking changes

## Phase 2: Content Generation (Parallel)

Launch description generator and review preparer in parallel:

Use the Agent tool to spawn the agent `gitx:pr:description-generator` to generate PR content:

```markdown
Agent(gitx:pr:description-generator):
  prompt: <change-analysis>[output from Phase 1]</change-analysis>
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Use the Agent tool to spawn the agent `gitx:pr:review-preparer` to prepare review notes:

```markdown
Agent(gitx:pr:review-preparer):
  prompt:
    Change Analysis: [output from Phase 1]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Phase 3: User Review

Present generated content:

```markdown
## Pull Request Preview

### Title
[generated title]

### Description
[generated description]

---

### Review Preparation

**Suggested Reviewers**: @reviewer1, @reviewer2

**Focus Areas for Review**:
1. [Area 1]
2. [Area 2]

**Self-Review Checklist**:
- [ ] [Item 1]
- [ ] [Item 2]

**Potential Concerns**:
- [Concern 1]
- [Concern 2]
```

Use the AskUserQuestion tool to ask how to proceed with the PR content:

```text
Question: "Review the generated PR content. How would you like to proceed?"
Options:
1. "Create PR as shown (Recommended)"
2. "Edit title" - Modify the title
3. "Edit description" - Modify the body
4. "Add draft flag" - Create as draft PR
5. "Cancel" - Abort PR creation
```

Handle user response:

- **Create**: Proceed to creation
- **Edit title**: Prompt for new title, update
- **Edit description**: Show editor-friendly format, update
- **Draft**: Add --draft flag
- **Cancel**: Exit

## Phase 4: Create PR

Create the pull request:

```bash
gh pr create --title "[title]" --body "[generated body]" --assignee @me
```

If draft requested:

- Add `--draft` flag

If labels suggested:

- Add `--label [labels]` flag

## Phase 5: Initialize Metadata

If `$NO_METADATA_SYNC` is `"true"`, skip this entire phase — the user has opted
out of automatic metadata writes.

Otherwise, after successful PR creation, initialize metadata for subsequent operations:

Use the Agent tool to run the agent `gitx:pr:metadata-fetcher`:

```markdown
Agent(gitx:pr:metadata-fetcher, prompt: "worktree: [current directory]")
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Report Results

Show:

````markdown
## Pull Request Created

### Details
- **PR Number**: #[number]
- **Title**: [title]
- **URL**: [url]
- **Status**: [open/draft]

### Suggested Reviewers
@reviewer1, @reviewer2

To add reviewers:
```bash
gh pr edit [number] --add-reviewer @reviewer1,@reviewer2
```

### Next Steps

If you need to:
- Respond to reviews: `/gitx:address-review`
- Add comments: `/gitx:comment-to-pr`
- Merge when ready: `/gitx:merge-pr`

### Review Preparation Notes

[Summary of review-preparer output]

````

## Fallback Mode

If orchestration fails:

Use the AskUserQuestion tool to ask how to handle the orchestration failure:

```text
Question: "Orchestrated PR creation encountered an issue. Continue with basic mode?"
Options:
1. "Yes, create basic PR" - Use simple title/body
2. "Retry orchestration" - Try again
3. "Cancel" - Abort
```

For basic mode:

### Basic Title Generation

Based on:

- Branch name convention: `feature/issue-123-description` → "feat: description (#123)"
- First commit message if it follows conventional commits
- Ask user if unclear

### Basic Body Generation

```markdown
## Summary

<Brief description based on commits>

## Changes

<List of changed files>

## Related Issues

<Issue references from commits/branch>

## Test Plan

- [ ] Tests added/updated
- [ ] Manual testing completed
```

## Error Handling

1. Not a git repository: Report error.
2. No commits to create PR: Suggest making changes first.
3. PR already exists: Show existing PR URL.
4. No permission: Check repository access.
5. CI required: Note that CI checks will run.
6. Agent failure: Fall back to basic mode.
