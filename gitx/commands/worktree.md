---
description: Manages git worktrees when needing isolated development environments. Use for parallel feature work or issue-based development.
argument-hint: "[ISSUE|TASK|BRANCH|NAME]"
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git switch:*), Bash(gh issue:*), AskUserQuestion, Skill(gitx:naming-branches), Skill(gitx:naming-worktrees), Skill(gitx:syncing-worktrees), Skill(gitx:parsing-issue-references), Skill(gitx:validating-directory-names)
model: sonnet
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
5. **Branch naming**: Use Skill tool with gitx:naming-branches
6. **Directory naming**: Use Skill tool with gitx:naming-worktrees

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

1. Check gh auth status: `gh auth status`
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

Use Skill tool with gitx:parsing-issue-references to parse the argument:

1. If skill returns `source_type` of "bare", "hash", "prefix", or "url": Treat as issue
2. If skill returns `source_type` of "branch": Treat as branch name (validate format)
3. If skill returns `source_type` of "unknown" AND argument contains `/`: Treat as branch name
4. Otherwise: Treat as task description

Based on argument type, create appropriate worktree:

**1. Issue number (e.g., "123", "#123", "issue-123"):**

- Run pre-flight checks (see Pre-flight Checks section)
- Extract the number
- Fetch issue details: `gh issue view <number> --json number,title,labels`
- Use Skill tool with gitx:naming-branches (see Branch Name Generation section)

**2. GitHub issue URL (e.g., `https://github.com/owner/repo/issues/123`):**

- Run pre-flight checks (see Pre-flight Checks section)
- Extract issue number from URL
- Proceed as with issue number above

**3. Branch name (contains "/" like "feature/my-feature"):**

- Use the branch name directly
- Validate it follows gitx:naming-branches format

**4. Task description (plain text like "add user authentication"):**

- Generate branch name using gitx:naming-branches skill:
  - Default to `feature/<slugified-description>`
  - Slugify: lowercase, replace spaces with hyphens, remove special chars

## Branch Name Generation

Generate branch name using ONLY the information already gathered:

1. For issues: Use title and labels from `gh issue view` output
2. For descriptions: Use the argument text directly
3. Do NOT read project files to determine branch type
4. Do NOT explore codebase to improve naming

Use Skill tool with gitx:naming-branches skill. Exact invocation format:

```text
Skill(gitx:naming-branches) with args:
- For issue-based: "issue <number> <title> --labels <label1,label2>"
- For task description: "feature <description>"
```

Example tool calls:

1. Issue with bug label:
   - Skill: `gitx:naming-branches`
   - Args: `issue 123 fix login error --labels bug,auth`
   - Expected output: `bugfix/issue-123-fix-login-error`

2. Issue with feature label:
   - Skill: `gitx:naming-branches`
   - Args: `issue 456 add dark mode --labels enhancement`
   - Expected output: `feature/issue-456-add-dark-mode`

3. Task description:
   - Skill: `gitx:naming-branches`
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
3. Use Skill tool with gitx:naming-worktrees to generate directory name options:
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

If gitx:naming-worktrees skill is unavailable or fails:

1. **Notify user**: "Note: Using simplified directory name (skill unavailable)"
2. **Fallback method**: Sanitize branch name directly
   - Remove type prefix (e.g., `feature/` → ``)
   - Remove issue patterns (e.g., `issue-123-` → ``)
   - Result is the directory name

3. **Example**:
   - Branch: `feature/issue-123-add-user-auth`
   - Fallback: `add-user-auth`

If skill returns empty list:

1. **Notify user**: "Note: Using simplified name (skill returned no options)"
2. Apply the same fallback method
3. If still empty, use the full branch name with `/` replaced by `-`

## Directory Collision Check

Before presenting options to user, check for existing worktrees:

1. Run `git worktree list` to get existing worktree paths
2. Extract directory names from paths
3. Filter out options that collide with existing directories
4. If all options collide, add numeric suffix to options (e.g., `auth-2`, `auth-3`, ...)
   - Maximum 10 suffix attempts (`auth`, `auth-2`, ..., `auth-10`)
   - If all 10 collide: "Error: Too many directories with similar names. Please choose a unique custom name."
5. Report collisions to user: "Note: `auth` already exists, showing alternatives"

## Directory Name Selection

Use AskUserQuestion to let user choose directory name:

1. Question: "Select worktree directory name for branch `<branch-name>`:"
2. Header: "Directory"
3. Options: [Generated options from gitx:naming-worktrees skill]
   - Each option shows the abbreviated name
   - Filter out branch-type words when standalone: `feature`, `bugfix`, `hotfix`, `release`, `chore`, `refactor`, `docs`
   - User can select "Other" for custom name
4. If user selects "Other" (custom name):
   - Ask for custom name
   - Validate against all rules (see Custom Name Validation)
   - Maximum 3 retry attempts
   - After 3 failed attempts, suggest auto-generated fallback: `<sanitized-branch>-custom`
   - Confirm the custom name

## Custom Name Validation

Use Skill tool with gitx:validating-directory-names to validate custom names.

The skill validates:

- Format rules (lowercase, hyphens, no special chars)
- Length rules (2-30 characters)
- Reserved names (git and system names)
- Collision with existing worktrees

On validation failure, the skill returns an error message with a suggested fix.

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

### Sync Repository

Use Skill tool with gitx:syncing-worktrees to sync the current branch before creating the worktree.
The skill handles:

- Detached HEAD detection
- Fetching latest from origin
- Stashing local changes if dirty
- Pulling with rebase
- Restoring stashed changes

If sync fails, follow the skill's error handling guidance.

### Create Worktree

After successful sync:

```bash
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
4. Use Skill gitx:naming-branches to generate branch name → `bugfix/issue-123-fix-login`
5. Use Skill gitx:naming-worktrees to generate directory options → `['login', 'fix-login']`
6. Check for directory collisions (none found)
7. **Ask user to select directory name**:
   - Question: "Select worktree directory name for branch `bugfix/issue-123-fix-login`:"
   - Options: ["login", "fix-login"] (user can select "Other" for custom name)
   - User selects: `fix-login`
8. **Confirm with AskUserQuestion**:
   - Question: "Create worktree with branch: `bugfix/issue-123-fix-login` at path: `../fix-login`?"
   - Options: ["Create as proposed", "Modify branch name", "Cancel"]
9. If confirmed, create worktree: `git worktree add -b bugfix/issue-123-fix-login ../fix-login`
10. Report success and STOP

### Example 2: Task description (no exploration)

User: `/gitx:worktree add user authentication`

Execution (no codebase exploration):

1. Parse argument directly as task description
2. Use Skill gitx:naming-branches: `feature add user authentication`
3. Use Skill gitx:naming-worktrees to generate directory options → `['authentication', 'user-authentication', 'add-user-authentication']`
4. Check for directory collisions (none found)
5. **Ask user to select directory name**:
   - Question: "Select worktree directory name for branch `feature/add-user-authentication`:"
   - Options: ["authentication", "user-authentication", "add-user-authentication"] (user can select "Other" for custom name)
   - User selects: `user-authentication`
6. **Confirm with AskUserQuestion**:
   - Question: "Create worktree with branch: `feature/add-user-authentication` at path: `../user-authentication`?"
   - Options: ["Create as proposed", "Modify branch name", "Cancel"]
7. If confirmed, create worktree: `git worktree add -b feature/add-user-authentication ../user-authentication`
8. Report success and STOP

### Example 3: Branch name (no exploration)

User: `/gitx:worktree feature/my-new-feature`

Execution (no codebase exploration):

1. Detect `/` in argument - treat as branch name
2. Validate format (lowercase, hyphens only)
3. Use Skill gitx:naming-worktrees to generate directory options → `['new-feature', 'my-new-feature']`
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
