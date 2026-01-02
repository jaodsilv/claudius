---
description: List or create git worktrees for isolated feature development
argument-hint: "[ISSUE|TASK|BRANCH|NAME]"
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git switch:*), Bash(gh issue:*), AskUserQuestion, Skill(gitx:conventional-branch), Skill(gitx:worktree-name)
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
5. **Branch naming**: Use Skill tool with gitx:conventional-branch
6. **Directory naming**: Use Skill tool with gitx:worktree-name

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
- Use Skill tool with gitx:conventional-branch (see Branch Name Generation section)

**2. GitHub issue URL (e.g., `https://github.com/owner/repo/issues/123`):**

- Run pre-flight checks (see Pre-flight Checks section)
- Extract issue number from URL
- Proceed as with issue number above

**3. Branch name (contains "/" like "feature/my-feature"):**

- Use the branch name directly
- Validate it follows gitx:conventional-branch format

**4. Task description (plain text like "add user authentication"):**

- Generate branch name using gitx:conventional-branch skill:
  - Default to `feature/<slugified-description>`
  - Slugify: lowercase, replace spaces with hyphens, remove special chars

## Branch Name Generation

Generate branch name using ONLY the information already gathered:

1. For issues: Use title and labels from `gh issue view` output
2. For descriptions: Use the argument text directly
3. Do NOT read project files to determine branch type
4. Do NOT explore codebase to improve naming

Use Skill tool with gitx:conventional-branch skill. Exact invocation format:

```text
Skill(gitx:conventional-branch) with args:
- For issue-based: "issue <number> <title> --labels <label1,label2>"
- For task description: "feature <description>"
```

Example tool calls:

1. Issue with bug label:
   - Skill: `gitx:conventional-branch`
   - Args: `issue 123 fix login error --labels bug,auth`
   - Expected output: `bugfix/issue-123-fix-login-error`

2. Issue with feature label:
   - Skill: `gitx:conventional-branch`
   - Args: `issue 456 add dark mode --labels enhancement`
   - Expected output: `feature/issue-456-add-dark-mode`

3. Task description:
   - Skill: `gitx:conventional-branch`
   - Args: `feature add user authentication`
   - Expected output: `feature/add-user-authentication`

Skill output rules:

1. Types: feature/, bugfix/, hotfix/, release/, chore/
2. Format: `<type>/<description>` or `<type>/issue-<number>-<description>`
3. Rules: lowercase, hyphens only, no consecutive hyphens, max 50 chars total

## Worktree Path

Calculate worktree path using abbreviated directory naming:

1. Get repository root: `git rev-parse --show-toplevel`
2. Get parent directory: `dirname` of root
3. Use Skill tool with gitx:worktree-name to generate directory name options:
   - Input: branch name (e.g., `feature/issue-123-add-user-auth`)
   - Output: list of options (e.g., `['auth', 'user-auth', 'add-user-auth']`)
4. Validate skill output (see Skill Fallback Behavior)
5. Check for directory collisions (see Directory Collision Check)
6. Present options to user via AskUserQuestion (see Directory Name Selection)
7. Final path: `<parent>/<selected-directory-name>`

Example:

1. Repo root: `/code/myproject`
2. Branch: `feature/issue-123-add-user-auth`
3. Skill output: `['auth', 'user-auth', 'add-user-auth']`
4. No collisions found
5. User selects: `user-auth`
6. Worktree: `/code/user-auth`

## Skill Fallback Behavior

If gitx:worktree-name skill is unavailable or fails:

1. **Fallback method**: Sanitize branch name directly
   - Remove type prefix (e.g., `feature/` → ``)
   - Remove issue patterns (e.g., `issue-123-` → ``)
   - Result is the directory name

2. **Example**:
   - Branch: `feature/issue-123-add-user-auth`
   - Fallback: `add-user-auth`

If skill returns empty list:

1. Apply the same fallback method
2. If still empty, use the full branch name with `/` replaced by `-`

## Directory Collision Check

Before presenting options to user, check for existing worktrees:

1. Run `git worktree list` to get existing worktree paths
2. Extract directory names from paths
3. Filter out options that collide with existing directories
4. If all options collide, add numeric suffix to options (e.g., `auth-2`)
5. Report collisions to user: "Note: `auth` already exists, showing alternatives"

## Directory Name Selection

Use AskUserQuestion to let user choose directory name:

1. Question: "Select worktree directory name for branch `<branch-name>`:"
2. Header: "Directory"
3. Options: [Generated options from gitx:worktree-name skill]
   - Each option shows the abbreviated name
   - Filter out branch-type words when standalone: `feature`, `bugfix`, `hotfix`, `release`, `chore`
   - User can select "Other" for custom name
4. If user selects "Other" (custom name):
   - Ask for custom name
   - Validate against all rules (see Custom Name Validation)
   - Maximum 3 retry attempts before suggesting an auto-generated name
   - Confirm the custom name

## Custom Name Validation

Custom directory names must pass all validations:

1. **Format rules**:
   - Lowercase only (a-z)
   - Hyphens for word separation (no underscores)
   - No consecutive hyphens
   - No leading or trailing hyphens
   - No special characters or spaces

2. **Length rules**:
   - Minimum: 2 characters
   - Maximum: 30 characters

3. **Reserved names** (reject these):
   - Git: `main`, `master`, `develop`, `HEAD`, `origin`
   - System: `tmp`, `temp`, `test`, `build`, `dist`, `node_modules`

4. **Collision check**: Must not match existing worktree directory

5. **Error messages**:
   - "Name must be lowercase" → suggest lowercase version
   - "Name too long (max 30 chars)" → suggest truncated version
   - "Reserved name" → suggest alternative
   - "Directory already exists" → suggest with numeric suffix

## Confirmation

Use AskUserQuestion tool with:

1. Question: "Create worktree?\n  Branch: `<branch-name>`\n  Directory: `<parent>/<selected-directory>`"
2. Header: "Confirm"
3. Options: ["Create as proposed", "Change directory name", "Cancel"]

Handle response:

1. "Create as proposed": Continue to worktree creation
2. "Change directory name": Go back to Directory Name Selection
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
# NOTE: <worktree-path> uses the abbreviated directory name selected by user
#       (e.g., ../user-auth) NOT the full branch name
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
4. Use Skill gitx:conventional-branch to generate branch name → `bugfix/issue-123-fix-login`
5. Use Skill gitx:worktree-name to generate directory options → `['login', 'fix-login']`
6. Check for directory collisions (none found)
7. **Ask user to select directory name**:
   - Question: "Select worktree directory name for branch `bugfix/issue-123-fix-login`:"
   - Options: ["login", "fix-login"] (user can select "Other" for custom name)
   - User selects: `fix-login`
8. **Confirm with AskUserQuestion**:
   - Question: "Create worktree?\n  Branch: `bugfix/issue-123-fix-login`\n  Directory: `../fix-login`"
   - Options: ["Create as proposed", "Change directory name", "Cancel"]
9. If confirmed, create worktree: `git worktree add -b bugfix/issue-123-fix-login ../fix-login`
10. Report success and STOP

### Example 2: Task description (no exploration)

User: `/gitx:worktree add user authentication`

Execution (no codebase exploration):

1. Parse argument directly as task description
2. Use Skill gitx:conventional-branch: → `feature/add-user-authentication`
3. Use Skill gitx:worktree-name to generate directory options → `['authentication', 'user-authentication', 'add-user-authentication']`
4. Check for directory collisions (none found)
5. **Ask user to select directory name**:
   - Question: "Select worktree directory name for branch `feature/add-user-authentication`:"
   - Options: ["authentication", "user-authentication", "add-user-authentication"] (user can select "Other" for custom name)
   - User selects: `user-authentication`
6. **Confirm with AskUserQuestion**:
   - Question: "Create worktree?\n  Branch: `feature/add-user-authentication`\n  Directory: `../user-authentication`"
   - Options: ["Create as proposed", "Change directory name", "Cancel"]
7. If confirmed, create worktree: `git worktree add -b feature/add-user-authentication ../user-authentication`
8. Report success and STOP

### Example 3: Branch name (no exploration)

User: `/gitx:worktree feature/my-new-feature`

Execution (no codebase exploration):

1. Detect `/` in argument - treat as branch name
2. Validate format (lowercase, hyphens only)
3. Use Skill gitx:worktree-name to generate directory options → `['new-feature', 'my-new-feature']`
   (Note: `feature` filtered out as branch-type word)
4. Check for directory collisions (none found)
5. **Ask user to select directory name**:
   - Question: "Select worktree directory name for branch `feature/my-new-feature`:"
   - Options: ["new-feature", "my-new-feature"] (user can select "Other" for custom name)
   - User selects: `new-feature`
6. **Confirm with AskUserQuestion**:
   - Question: "Create worktree?\n  Branch: `feature/my-new-feature`\n  Directory: `../new-feature`"
   - Options: ["Create as proposed", "Change directory name", "Cancel"]
7. If confirmed, create worktree: `git worktree add -b feature/my-new-feature ../new-feature`
8. Report success and STOP
