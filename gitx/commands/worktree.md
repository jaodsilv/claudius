---
description: List or create git worktrees for isolated feature development
argument-hint: "[ISSUE|TASK|BRANCH|NAME]"
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git switch:*), Bash(gh issue:*), AskUserQuestion, Skill(conventional-branch)
---

# Worktree Management

Manage git worktrees for isolated feature development.
Without arguments, lists existing worktrees.
With an argument, creates a new worktree with appropriate branch naming.

## Gather Context

Get current repository state:

- Repository root: `../main`
- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`
- Main branch name: `main`

## CRITICAL: Command Boundaries

This command MUST stop after reporting success. Do NOT:

1. Navigate to the new worktree
2. Perform any development work
3. Run any commands in the worktree
4. Start implementing any features or fixes

The user will manually navigate to the worktree and decide what to do next.
If the user wants an orchestrated workflow that includes development,
they should use `/gitx:fix-issue` instead.

## CRITICAL: No Codebase Exploration

This command gathers ALL information from these sources ONLY:

1. **Git metadata**: Use git/gh commands in allowed-tools
2. **Issue data**: Use `gh issue view` for title and labels
3. **User input**: Parse $ARGUMENTS directly
4. **User clarification**: Use AskUserQuestion for ambiguity
5. **Branch naming**: Use Skill tool with conventional-branch

FORBIDDEN actions:

1. Reading project files (Read, Glob, Grep tools)
2. Analyzing code structure or patterns
3. Using Task tool for anything
4. Making assumptions about implementation details

If information is unclear or missing, use AskUserQuestion - do not explore.

## Enforcement Check

**SELF-CHECK REQUIREMENT**: Before proceeding to worktree creation:

If during this execution you used ANY of: Read, Glob, Grep, or Task tools:

1. STOP immediately
2. Report: "ERROR: Command violated no-exploration constraint"
3. Do NOT proceed with worktree creation
4. Apologize and restart execution using only allowed-tools

This is a hard requirement. The worktree command MUST NOT explore the codebase.

## Pre-flight Checks

Before attempting issue lookup, if argument looks like issue number or URL:

1. Check gh auth status: `gh auth status 2>&1`
2. If not authenticated, report error and provide guidance:
   "Run `gh auth login` to authenticate"
3. Exit without proceeding if auth check fails

## Execution Logic

### If no argument provided ($ARGUMENTS is empty)

Display the existing worktrees in a formatted table:

1. Run `git worktree list` to get all worktrees
2. Format output showing: path, branch, and commit hash
3. Indicate which worktree is current

### If argument provided

Parse the argument to determine its type by checking in order:

1. If matches `^\d+$` or `^#\d+$` or `^issue-\d+$`: Extract number, treat as issue
2. If matches `^https?://github\.com/[^/]+/[^/]+/issues/(\d+)`:
   Extract number from URL, treat as issue
3. If contains `/`: Treat as branch name (validate format)
4. Otherwise: Treat as task description

Based on argument type, create appropriate worktree:

**1. Issue number (e.g., "123", "#123", "issue-123"):**

- Run pre-flight checks (see Pre-flight Checks section)
- Extract the number
- Fetch issue details: `gh issue view <number> --json number,title,labels`
- Use Skill tool with conventional-branch (see Branch Name Generation section)

**2. GitHub issue URL (e.g., `https://github.com/owner/repo/issues/123`):**

- Run pre-flight checks (see Pre-flight Checks section)
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

Generate branch name using ONLY the information already gathered:

1. For issues: Use title and labels from `gh issue view` output
2. For descriptions: Use the argument text directly
3. Do NOT read project files to determine branch type
4. Do NOT explore codebase to improve naming

Use Skill tool with conventional-branch skill. Exact invocation format:

```text
Skill(conventional-branch) with args:
- For issue-based: "issue <number> <title> --labels <label1,label2>"
- For task description: "feature <description>"
```

Example tool calls:

1. Issue with bug label:
   - Skill: `conventional-branch`
   - Args: `issue 123 fix login error --labels bug,auth`
   - Expected output: `bugfix/issue-123-fix-login-error`

2. Issue with feature label:
   - Skill: `conventional-branch`
   - Args: `issue 456 add dark mode --labels enhancement`
   - Expected output: `feature/issue-456-add-dark-mode`

3. Task description:
   - Skill: `conventional-branch`
   - Args: `feature add user authentication`
   - Expected output: `feature/add-user-authentication`

Skill output rules:

1. Types: feature/, bugfix/, hotfix/, release/, chore/
2. Format: `<type>/<description>` or `<type>/issue-<number>-<description>`
3. Rules: lowercase, hyphens only, no consecutive hyphens, max 50 chars total

## Worktree Path

Calculate worktree path as sibling directory:

1. Get repository root: `git rev-parse --show-toplevel`
2. Get parent directory: `dirname` of root
3. Sanitize branch name: Replace `/` with `-` for filesystem safety
4. Final path: `<parent>/<sanitized-branch-name>`

Example:

1. Repo root: `/code/myproject`
2. Branch: `feature/issue-123-auth`
3. Sanitized: `feature-issue-123-auth`
4. Worktree: `/code/feature-issue-123-auth`

## Confirmation

Use AskUserQuestion tool with:

1. Question: "Create worktree with branch: `<branch-name>` at path: `<worktree-path>`?"
2. Options: ["Create as proposed", "Modify branch name", "Cancel"]

Handle response:

1. "Create as proposed": Continue to worktree creation
2. "Modify branch name": Ask for new name, validate, confirm again
3. "Cancel": Exit with message "Worktree creation cancelled"

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

FORBIDDEN command variations (NEVER use these):

1. `git worktree add -b <branch> <path> origin/main` - NO start-point
2. `git worktree add -b <branch> <path> main` - NO start-point
3. `git worktree add -b <branch> <path> <any-commit>` - NO start-point
4. `git worktree add <path> origin/main` - NO tracking existing branches
5. Any variation with additional arguments after `<worktree-path>`

The ONLY valid format is: `git worktree add -b <branch-name> <worktree-path>`

Report success with:

1. Worktree path: `<path>`
2. Branch name: `<branch>`
3. STOP HERE - do not navigate or perform any work
4. User next steps: "cd `<path>` to start working"

**CRITICAL**: After reporting success, this command ends. Do not proceed further.

## Error Handling

1. Branch already exists: Suggest using existing branch or different name.
2. Worktree path exists: Suggest different path.
3. Issue not found: Report error and suggest checking issue number.
4. gh CLI not authenticated: Provide guidance to run `gh auth login`.

## Examples

### Example 1: Issue-based (no exploration)

User: `/gitx:worktree 123`

Execution (no codebase exploration):

1. Check gh auth: `gh auth status`
2. Fetch issue: `gh issue view 123 --json number,title,labels`
3. Parse response (do NOT read any project files)
4. Use Skill conventional-branch to generate branch name
5. Calculate worktree path
6. **Confirm with AskUserQuestion**:
   - Question: "Create worktree with branch: `bugfix/issue-123-fix-login` at path: `../bugfix-issue-123-fix-login`?"
   - Options: ["Create as proposed", "Modify branch name", "Cancel"]
7. If confirmed, create worktree: `git worktree add -b bugfix/issue-123-fix-login ../bugfix-issue-123-fix-login`
8. Report success and STOP

### Example 2: Task description (no exploration)

User: `/gitx:worktree add user authentication`

Execution (no codebase exploration):

1. Parse argument directly as task description
2. Use Skill conventional-branch: `feature add user authentication`
3. Calculate worktree path
4. **Confirm with AskUserQuestion**:
   - Question: "Create worktree with branch: `feature/add-user-authentication` at path: `../feature-add-user-authentication`?"
   - Options: ["Create as proposed", "Modify branch name", "Cancel"]
5. If confirmed, create worktree: `git worktree add -b feature/add-user-authentication ../feature-add-user-authentication`
6. Report success and STOP

### Example 3: Branch name (no exploration)

User: `/gitx:worktree feature/my-new-feature`

Execution (no codebase exploration):

1. Detect `/` in argument - treat as branch name
2. Validate format (lowercase, hyphens only)
3. Calculate worktree path
4. **Confirm with AskUserQuestion**:
   - Question: "Create worktree with branch: `feature/my-new-feature` at path: `../feature-my-new-feature`?"
   - Options: ["Create as proposed", "Modify branch name", "Cancel"]
5. If confirmed, create worktree: `git worktree add -b feature/my-new-feature ../feature-my-new-feature`
6. Report success and STOP
