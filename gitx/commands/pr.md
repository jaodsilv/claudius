---
description: Create pull request for current branch
argument-hint: ""
allowed-tools: Bash(git:*), Bash(gh pr:*), AskUserQuestion
---

# Create Pull Request

Create a GitHub pull request for the current branch.

## Gather Context

Get repository and branch state:
- Current branch: !`git branch --show-current`
- Main branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`
- Remote status: !`git status -sb`
- Commits in branch: !`git log --oneline main..HEAD 2>/dev/null || git log --oneline -10`
- Changed files: !`git diff --stat main..HEAD 2>/dev/null || echo ""`

Check for existing PR:
- `gh pr view --json number,url,state 2>/dev/null`

## Pre-flight Checks

### Check branch is not main
If on main/master:
- Report: "Cannot create PR from main branch"
- Suggest: Create a feature branch first

### Check remote is up to date
- `git fetch origin`
- Compare local and remote: `git log origin/<branch>..HEAD 2>/dev/null`

If local is ahead of remote:
- Push first: `git push -u origin <branch>`

If remote doesn't exist:
- Create and push: `git push -u origin <branch>`

### Check for existing PR
If PR already exists:
- Report: "PR #<number> already exists for this branch"
- Show: URL and state
- Suggest: Use `/gitx:respond` to address feedback

## Analyze Changes

Review all commits from base to HEAD:
- `git log --pretty=format:"%s%n%b" main..HEAD`

Identify:
- Type of change (feature, fix, refactor, etc.)
- Related issues (from commit messages or branch name)
- Test coverage (look for test file changes)

## Generate PR Content

### Title
Based on:
- Branch name convention: `feature/issue-123-description` → "feat: description (#123)"
- First commit message if it follows conventional commits
- Ask user if unclear

### Body
Generate structured body:
```markdown
## Summary
<1-3 bullet points summarizing changes>

## Changes
<list of significant changes>

## Related Issues
<Closes #123 if issue number found>

## Test Plan
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] <specific test scenarios>

## Screenshots
<if UI changes, note to add screenshots>
```

## Confirmation

Use AskUserQuestion to confirm PR details:

Show:
- Title: <proposed title>
- Base: <main branch>
- Head: <current branch>
- Summary preview

Options:
1. "Create PR as shown" - proceed
2. "Edit title" - modify title
3. "Edit description" - modify body
4. "Add draft flag" - create as draft
5. "Cancel" - abort

## Create PR

Create the pull request:
```bash
gh pr create \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body content>
EOF
)" \
  --assignee @me \
  --base <main-branch>
```

If draft requested:
- Add `--draft` flag

## Report Results

Show:
- PR number and URL
- Title
- Status (open/draft)

Suggest next steps:
```
PR created successfully!

View PR: <url>

If you need to:
- Respond to reviews: /gitx:respond
- Add comments: /gitx:comment-to-pr
- Merge when ready: /gitx:merge-pr
```

## Error Handling

- Not a git repository: Report error
- No commits to create PR: Suggest making changes first
- PR already exists: Show existing PR URL
- No permission: Check repository access
- CI required: Note that CI checks will run
