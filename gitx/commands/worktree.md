---
description: List or create git worktrees for isolated feature development
argument-hint: "[ISSUE|TASK|BRANCH|NAME]"
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git switch:*), Bash(gh issue:*), AskUserQuestion
---

# Worktree Management

Manage git worktrees for isolated feature development. Without arguments, lists existing worktrees.
With an argument, creates a new worktree with appropriate branch naming.

## Gather Context

Get current repository state:
- Repository root: !`git rev-parse --show-toplevel`
- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`
- Main branch name: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`

## Execution Logic

### If no argument provided ($ARGUMENTS is empty)

Display the existing worktrees in a formatted table:
1. Run `git worktree list` to get all worktrees
2. Format output showing: path, branch, and commit hash
3. Indicate which worktree is current

### If argument provided

Parse the argument to determine its type and create appropriate worktree:

**1. Issue number (e.g., "123", "#123", "issue-123"):**
- Extract the number
- Fetch issue details: `gh issue view <number> --json number,title,labels`
- Generate branch name using conventional-branch skill:
  - If issue has "bug" or "bugfix" label: `bugfix/issue-<number>-<short-title>`
  - If issue has "feature" or "enhancement" label: `feature/issue-<number>-<short-title>`
  - Default: `feature/issue-<number>-<short-title>`
- Short title: lowercase, hyphens, max 30 chars, no special characters

**2. GitHub issue URL (e.g., "<https://github.com/owner/repo/issues/123>"):**
- Extract issue number from URL
- Proceed as with issue number above

**3. Branch name (contains "/" like "feature/my-feature"):**
- Use the branch name directly
- Validate it follows conventional-branch format

**4. Task description (plain text like "add user authentication"):**
- Generate branch name using conventional-branch skill:
  - Default to `feature/<slugified-description>`
  - Slugify: lowercase, replace spaces with hyphens, remove special chars

## Branch Name Generation

Use the @conventional-branch skill for naming:
- Types: feature/, bugfix/, hotfix/, release/, chore/
- Format: `<type>/<description>` or `<type>/issue-<number>-<description>`
- Rules: lowercase, hyphens only, no consecutive hyphens

## Worktree Path

Create worktree as sibling directory:
- Get parent of repository root
- Path format: `../<branch-name>` (relative to repo root)
- Example: If repo is at `/code/myproject` and branch is `feature/issue-123-auth`, worktree path is `/code/feature-issue-123-auth`

## Confirmation

Before creating, use AskUserQuestion to confirm:
- Proposed branch name
- Worktree path
- Base branch (default: main)

Options:
1. "Create as proposed" - proceed with suggested names
2. "Modify branch name" - let user provide alternative
3. "Cancel" - abort operation

## Create Worktree

After confirmation:
1. Fetch latest from origin: `git fetch origin`
2. Create worktree with new branch: `git worktree add -b <branch-name> <worktree-path> origin/<main-branch>`
3. Report success with:
   - Worktree path
   - Branch name
   - Next steps: "cd <path> to start working"

## Error Handling

- If branch already exists: Suggest using existing branch or different name
- If worktree path exists: Suggest different path
- If issue not found: Report error and suggest checking issue number
- If gh CLI not authenticated: Provide guidance to run `gh auth login`
