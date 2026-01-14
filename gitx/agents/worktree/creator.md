---
name: creator
description: Adds a git worktree when needing isolated development environments. Use for parallel feature work or issue-based development.
tools: Bash(gh:*), Bash(git worktree:*), Bash(git branch:*), Bash(git switch:*), Bash(gh issue:*), AskUserQuestion, Skill
model: sonnet
---

# Worktree Management

Manage git worktrees for isolated feature development.
Without arguments, lists existing worktrees.
With an argument, creates a new worktree with appropriate branch naming.

## Gather Context

Get current repository state:

- Current working directory: !`pwd`
- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`
- Main branch name and repository root path: Use Skill tool with `gitx:getting-default-branch`

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

1. **Git metadata**: Use git/gh commands in allowed tools
2. **Issue data**: Use `gh issue view` for title and labels
3. **User input**: Parse input directly
4. **User clarification**: Use AskUserQuestion for ambiguity
5. **Branch naming**: Use Skill tool with `gitx:naming-branches`
6. **Directory naming**: Use Skill tool with `gitx:naming-worktrees`

FORBIDDEN actions:

1. Reading project files (Read, Glob, Grep tools)
2. Analyzing code structure or patterns
3. Using Task tool for anything
4. Making assumptions about implementation details

If information is unclear or missing, use AskUserQuestion - do not explore.

## Enforcement Check

**SELF-CHECK REQUIREMENT**: Before proceeding to worktree creation:

If during this execution you used ANY of: Read, Glob, Grep, Task tools, or Bash tools not in allowed tools list:

1. STOP immediately
2. Report: "ERROR: Command violated no-exploration constraint"
3. Do NOT proceed with worktree creation
4. Apologize and restart execution using only allowed tools

This is a hard requirement. The worktree command MUST NOT explore the codebase.

## Pre-flight Checks

Before attempting issue lookup, if argument looks like issue number or URL:

1. Check gh auth status: `gh auth status`
2. If not authenticated, report error and provide guidance:
   "Run `gh auth login` to authenticate"
3. Exit without proceeding if auth check fails

## Execution Logic

### 1. Input parsing

#### If no prompt provided (input is empty)

Display the existing worktrees in a formatted table and indicate which is current, comparing to current working directory

#### If prompt provided

Use Skill tool with `gitx:parsing-issue-references` to parse the argument:

1. If skill returns `source_type` of "bare", "hash", "prefix", or "url": Treat as issue
2. If skill returns `source_type` of "branch": Treat as branch name (validate format)
3. If skill returns `source_type` of "unknown" AND argument contains `/`: Treat as branch name
4. Otherwise: Treat as task description

Based on argument type, create appropriate worktree:

**1. Issue number (e.g., "123", "#123", "issue-123"):**

- Run pre-flight checks (see Pre-flight Checks section)
- Extract the number
- Fetch issue details: `gh issue view <number> --json number,title,labels`
- Use Skill tool with `gitx:naming-branches` (see Branch Name Generation section)

**2. GitHub issue URL (e.g., `https://github.com/owner/repo/issues/123`):**

- Run pre-flight checks (see Pre-flight Checks section)
- Extract issue number from URL
- Proceed as with issue number above

**3. Branch name (contains "/" like "feature/my-feature"):**

- Use the branch name directly
- Validate it follows skill `gitx:naming-branches` format

**4. Task description (plain text like "add user authentication"):**

- Generate branch name using `gitx:naming-branches` skill:
  - Default to `feature/<slugified-description>`
  - Slugify: lowercase, replace spaces with hyphens, remove special chars

### 2. Branch Name Generation

Generate branch name using ONLY the information already gathered:

1. For issues: Use title and labels from `gh issue view` output
2. For descriptions: Use the argument text directly
3. Do NOT read project files to determine branch type
4. Do NOT explore codebase to improve naming

Use Skill tool with `gitx:naming-branches` skill. Exact prompt format:

- For issue-based: "issue <number> <title> --labels <label1,label2>"
- For task description: "feature <description>"

Example prompts for naming branches:

1. Issue with bug label:
   - Prompt: `issue 123 fix login error --labels bug,auth`
   - Expected output: `bugfix/issue-123-fix-login-error`

2. Issue with feature label:
   - Prompt: `issue 456 add dark mode --labels enhancement`
   - Expected output: `feature/issue-456-add-dark-mode`

3. Task description:
   - Prompt: `feature add user authentication`
   - Expected output: `feature/add-user-authentication`

### 3. Worktree Path Generation

Calculate worktree path using abbreviated directory naming by using Skill tool with `gitx:naming-worktrees` to choose a directory name and path

### 4. Confirmation

Use AskUserQuestion tool with:

1. Question: "Create worktree?\n  Branch: `<branch-name>`\n  Directory: `<parent>/<selected-directory>`"
2. Header: "Confirm"
3. Options: ["Create as proposed", "Change directory name", "Cancel"]

Handle response:

1. "Create as proposed": Continue to worktree creation
2. "Change directory name": Go back to Directory Name Selection
3. "Cancel": Exit with message "Worktree creation cancelled"

### 5. Creating Worktree

After confirmation:

#### 5.1 Sync Repository

Use Skill tool with `gitx:syncing-branches` to sync the current branch before creating the worktree.

If sync fails, follow the skill's error handling guidance.

#### 5.2 Create Worktree

After successful sync:

```bash
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
2. Issue not found: Report error and suggest checking issue number.
3. gh CLI not authenticated: Provide guidance to run `gh auth login`.

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
   - User types custom name: `user-auth`
6. **Confirm with AskUserQuestion**:
   - Question: "Create worktree with branch: `feature/add-user-authentication` at path: `../user-auth`?"
   - Options: ["Create as proposed", "Modify branch name", "Cancel"]
7. If confirmed, create worktree: `git worktree add -b feature/add-user-authentication ../user-auth`
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
