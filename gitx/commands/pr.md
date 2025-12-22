---
description: Create pull request for current branch
argument-hint: ""
allowed-tools: Bash(git:*), Bash(gh pr:*), Task, Read, Write, AskUserQuestion
---

# Create Pull Request (Orchestrated)

Create a GitHub pull request for the current branch using multi-agent orchestration for comprehensive change analysis and professional PR content.

## Gather Context

Get repository and branch state:
- Current branch: !`git branch --show-current`
- Main branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`
- Remote status: !`git status -sb`

Check for existing PR:
- `gh pr view --json number,url,state 2>/dev/null`

## Pre-flight Checks

### Check branch is not main
If on main/master:
- Report: "Cannot create PR from main branch"
- Suggest: Create a feature branch first
- Exit

### Check for existing PR
If PR already exists:
- Report: "PR #<number> already exists for this branch"
- Show: URL and state
- Suggest: Use `/gitx:respond` to address feedback
- Exit

### Check remote is up to date

```bash
git fetch origin
git log origin/<branch>..HEAD 2>/dev/null
```

If local is ahead of remote:
- Push first: `git push -u origin <branch>`

If remote doesn't exist:
- Create and push: `git push -u origin <branch>`

## Phase 1: Change Analysis

Launch change analyzer:
```
Task (gitx:change-analyzer):
  Branch: [current-branch]
  Base: [main-branch]

  Analyze:
  - All commits from base to HEAD
  - Files changed (added, modified, deleted)
  - Change type and scope
  - Related issues
  - Breaking changes
  - Test coverage assessment
```

Wait for analysis to complete.

Store key results:
- Change type (feature, fix, etc.)
- Related issues
- Files summary
- Breaking changes

## Phase 2: Content Generation (Parallel)

Launch description generator and review preparer in parallel:

```
Task (gitx:description-generator):
  Change Analysis: [output from Phase 1]

  Generate:
  - PR title (conventional format)
  - PR body (Summary, Changes, Related Issues, Test Plan)
  - Suggested labels
```

```
Task (gitx:review-preparer):
  Change Analysis: [output from Phase 1]

  Identify:
  - Potential review concerns
  - Suggested reviewers
  - Self-review checklist
  - Areas needing attention
```

Wait for both to complete.

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

Use AskUserQuestion:
```
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
gh pr create \
  --title "[title]" \
  --body "$(cat <<'EOF'
[generated body]
EOF
)" \
  --assignee @me \
  --base [main-branch]
```

If draft requested:
- Add `--draft` flag

If labels suggested:
- Add `--label [labels]` flag

## Report Results

Show:
```markdown
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
- Respond to reviews: `/gitx:respond`
- Add comments: `/gitx:comment-to-pr`
- Merge when ready: `/gitx:merge-pr`

### Review Preparation Notes
[Summary of review-preparer output]
```

## Fallback Mode

If orchestration fails:
```
AskUserQuestion:
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

- Not a git repository: Report error
- No commits to create PR: Suggest making changes first
- PR already exists: Show existing PR URL
- No permission: Check repository access
- CI required: Note that CI checks will run
- Agent failure: Fall back to basic mode
