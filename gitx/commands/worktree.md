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

Options:
1. "Create as proposed" - proceed with suggested names
2. "Modify branch name" - let user provide alternative
3. "Cancel" - abort operation

## Create Worktree

After confirmation:

```bash
# Verify not in detached HEAD state
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "Error: Cannot create worktree from detached HEAD state."
  echo "Please checkout a branch first: git checkout <branch-name>"
  exit 1
fi

# Fetch latest from origin
git fetch origin

# Stash local changes if working directory is dirty
STASHED=false
if [ -n "$(git status --porcelain)" ]; then
  git stash --include-untracked
  STASHED=true
fi

# Pull latest on current branch
if ! git pull --rebase origin "$CURRENT_BRANCH"; then
  echo "Error: Pull failed. Please resolve conflicts manually."
  if [ "$STASHED" = true ]; then
    echo "Note: Your changes are still in stash. Run 'git stash pop' after resolving."
  fi
  exit 1
fi

# Pop stash if we stashed earlier (conflicts are non-fatal, just warn user)
if [ "$STASHED" = true ]; then
  if ! git stash pop; then
    echo "Warning: Stash pop had conflicts. Your changes are still in stash."
    echo "Continuing with worktree creation. Run 'git stash pop' manually later."
  fi
fi

# Create worktree with new branch
# CRITICAL: Do NOT add any start-point (like origin/main or main) after the path
# The command MUST be exactly as shown below - no additional arguments
git worktree add -b <branch-name> <worktree-path>
```

Report success with:

1. Worktree path
2. Branch name
3. Next steps: "cd <path> to start working"

## CRITICAL: Command Boundaries

This command MUST stop after reporting success. Do NOT:

1. Navigate to the new worktree
2. Perform any development work
3. Run any commands in the worktree
4. Start implementing any features or fixes

The user will manually navigate to the worktree and decide what to do next.
If the user wants an orchestrated workflow that includes development, they should use `/gitx:fix-issue` instead.

## Error Handling

1. Branch already exists: Suggest using existing branch or different name.
2. Worktree path exists: Suggest different path.
3. Issue not found: Report error and suggest checking issue number.
4. gh CLI not authenticated: Provide guidance to run `gh auth login`.
