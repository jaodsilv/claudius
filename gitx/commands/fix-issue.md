---
description: Orchestrates full fix workflow when addressing a GitHub issue. Use for end-to-end issue resolution with worktree setup.
argument-hint: "[ISSUE]"
allowed-tools: Bash(git:*), Bash(gh:*), Read, Task, Skill, TodoWrite, Write, AskUserQuestion, Skill(gitx:syncing-worktrees), Skill(gitx:parsing-issue-references)
---

# Fix Issue (Orchestrated)

Complete orchestrated workflow to fix a GitHub issue: analyzes the issue, explores the codebase,
plans implementation, creates a worktree, and delegates to a development workflow.

## Parse Arguments

Use Skill tool with gitx:parsing-issue-references to parse $ARGUMENTS:

- Issue number (required): Supports "123", "#123", "issue-123", or GitHub issue URL
- If parsing fails, report error with supported formats

## Initialize Progress Tracking

```text
TodoWrite:
1. [ ] Analyze issue requirements
2. [ ] Explore codebase for relevant files
3. [ ] Create implementation plan
4. [ ] Get user approval on plan
5. [ ] Set up worktree
6. [ ] Complete development
7. [ ] Commit and prepare for PR
```

## Phase 1: Issue Analysis

Mark "Analyze issue requirements" as in_progress.

Launch issue analyzer:

```text
Task (gitx:issue-analyzer):
  Issue Number: [number]

  Analyze the issue to extract:
  - Explicit and implicit requirements
  - Acceptance criteria
  - Complexity estimate (XS/S/M/L/XL)
  - Issue type (bug/feature/enhancement/refactor)
  - Key terms for code search
  - Related issues and dependencies
```

Wait for analysis to complete.

Store key results:

- Issue type
- Complexity
- Key terms
- Requirements summary

Mark "Analyze issue requirements" as completed.

## Phase 2: Codebase Exploration

Mark "Explore codebase for relevant files" as in_progress.

Launch codebase navigator:

```text
Task (gitx:codebase-navigator):
  Issue Analysis: [summary from Phase 1]
  Key Terms: [terms from Phase 1]

  Find:
  - Files to modify
  - Patterns to follow
  - Test files needed
  - Impact assessment
  - Similar implementations to reference
```

Wait for exploration to complete.

Store key results:

- Files to modify
- Patterns identified
- Test requirements

Mark "Explore codebase for relevant files" as completed.

## Phase 3: Implementation Planning

Mark "Create implementation plan" as in_progress.

Launch implementation planner:

```text
Task (gitx:implementation-planner):
  Issue Analysis:
  [Full output from Phase 1]

  Codebase Navigation:
  [Full output from Phase 2]

  Create detailed implementation plan with:
  - Phased approach
  - Specific files and changes
  - Test strategy
  - Commit boundaries
  - Verification steps
```

Wait for plan to complete.

Mark "Create implementation plan" as completed.

## Phase 4: User Approval (Quality Gate)

Mark "Get user approval on plan" as in_progress.

Present the implementation plan summary:

```markdown
## Implementation Plan for Issue #[number]

### Issue: [title]
**Type**: [bug/feature/etc]
**Complexity**: [XS-XL]

### Summary
[2-3 sentence summary of the approach]

### Files to Modify
- [file1.ts] - [what changes]
- [file2.ts] - [what changes]

### Phases
1. [Phase 1 name] - [description]
2. [Phase 2 name] - [description]

### Estimated Effort
[complexity and time description]
```

Use AskUserQuestion:

```text
Question: "Review the implementation plan for Issue #[number]. How would you like to proceed?"
Options:
1. "Approve and continue (Recommended)" - Proceed with worktree setup and development
2. "Modify the plan" - Adjust approach before proceeding
3. "Add more detail" - Expand specific sections
4. "Cancel" - Abort the workflow
```

Handle user response:

- **Approve**: Mark complete, proceed to Phase 5
- **Modify**: Gather feedback, update plan, re-present
- **Add detail**: Ask which section, expand, re-present
- **Cancel**: Clean up and exit

Mark "Get user approval on plan" as completed.

## Phase 5: Worktree Setup

Mark "Set up worktree" as in_progress.

### Determine Branch Name

Based on issue type from analysis:

- Bug → `bugfix/issue-[number]-[slug]`
- Feature → `feature/issue-[number]-[slug]`
- Enhancement → `feature/issue-[number]-[slug]`
- Refactor → `refactor/issue-[number]-[slug]`
- Docs → `docs/issue-[number]-[slug]`

Slug is generated from issue title (lowercase, hyphenated, max 30 chars).

### Generate Directory Name Options

Use Skill tool with gitx:naming-worktrees:

- Input: [branch-name] (e.g., `feature/issue-123-add-user-auth`)
- Output: List of abbreviated directory options (e.g., `['auth', 'user-auth', 'add-user-auth']`)

**Fallback Behavior**:

If skill is unavailable or fails:

1. **Notify user**: "Note: Using simplified directory name (skill unavailable)"
2. Sanitize branch name directly:
   - Remove type prefix (e.g., `feature/` → ``)
   - Remove issue patterns (e.g., `issue-123-` → ``)
3. Use sanitized name as single option

If skill returns empty list:

1. **Notify user**: "Note: Using simplified name (skill returned no options)"
2. Apply same fallback method
3. If still empty, use branch name with `/` replaced by `-`

**Collision Check**:

Before presenting options:

1. Run `git worktree list` to get existing directories
2. Filter out colliding options
3. If all collide, add numeric suffix (e.g., `auth-2`, `auth-3`, ...)
   - Maximum 10 suffix attempts (`auth`, `auth-2`, ..., `auth-10`)
   - If all 10 collide: "Error: Too many directories with similar names. Please choose a unique custom name."

Use AskUserQuestion to let user select:

- Question: "Select worktree directory name for branch `[branch-name]`:"
- Header: "Directory"
- Options: [skill output options] (user can select "Other" for custom name)

Store selected name for WORKTREE_PATH.

### Sync and Create Worktree

Use Skill tool with gitx:syncing-worktrees to sync the current branch.
The skill handles detached HEAD detection, fetching, stashing, pulling, and restoring.

If sync fails, follow the skill's error handling guidance.

After successful sync, create the worktree:

```bash
# Create worktree as sibling directory
# Use the abbreviated directory name selected by user (not the full branch name)
WORKTREE_PATH="../[selected-directory-name]"
git worktree add -b [branch-name] "$WORKTREE_PATH"
```

Report worktree location:

```text
Worktree created:
  Path: [path]
  Branch: [branch-name]

Note: Development will continue in the worktree context.
```

Mark "Set up worktree" as completed.

## Phase 6: Development Delegation

Mark "Complete development" as in_progress.

### Workflow Selection

Use AskUserQuestion:

```text
Question: "Which development approach would you like to use for Issue #[number]?"
Options:
1. "Feature development workflow (Recommended)" - Guided feature development with code architecture
2. "TDD workflow" - Test-driven development with red-green-refactor
3. "Manual development" - Work independently with implementation plan
4. "Skip development" - I'll develop later, just set up the worktree
```

### Delegate Based on Choice

**Feature Development Workflow**:

```text
Skill (feature-dev:feature-dev):
  Context: Issue #[number] - [title]

  Issue Analysis:
  [Summary of requirements and acceptance criteria]

  Implementation Plan:
  [Key phases and files from plan]

  Relevant Files:
  [Files to modify from codebase navigation]
```

**TDD Workflow**:

```text
Skill (tdd-workflows:tdd-orchestrator):
  Context: Issue #[number] - [title]

  Test Requirements:
  [Test strategy from implementation plan]

  Implementation:
  [Implementation phases from plan]
```

**Manual Development**:
Provide the full implementation plan:

```markdown
## Manual Development Guide for Issue #[number]

### Implementation Plan
[Full plan content]

### Files to Work On
[File list with details]

### Patterns to Follow
[Pattern examples from codebase navigation]

### Verification Steps
[How to verify changes]

I'm available to help with any questions as you implement.
```

**Skip Development**:

```text
Worktree is ready at [path] on branch [branch-name].

When you're ready to continue:
- Use `/gitx:commit-push` to commit changes
- Use `/gitx:pr` to create a pull request
```

Skip to Phase 7 reporting.

### Graceful Fallback

If requested workflow not available:

```text
The [workflow] workflow is not available in your setup.

Available options:
1. Manual development with implementation plan
2. Basic guided development

Would you like to proceed with an alternative?
```

Mark "Complete development" as completed.

## Phase 7: Completion

Mark "Commit and prepare for PR" as in_progress.

Once development is complete:

### Check for Changes

```bash
git status
git diff --stat
```

If no changes:

- Report: "No changes detected in worktree"
- Suggest: "Make changes and run `/gitx:commit-push` when ready"
- Exit

### Commit and Push

If changes exist:

```text
Invoke /gitx:commit-push

The commit message should reference the issue:
"[type]: [description]

Fixes #[number]

[Details from implementation]"
```

### Suggest PR Creation

````markdown
## Development Complete for Issue #[number]

### Changes Made
[Summary of changes]

### Commits
[List of commits]

### Next Steps

To create a pull request:

```text
/gitx:pr
```

Or to comment on the issue with progress:

```text
/gitx:comment-to-issue [number] "Implementation complete, PR forthcoming"
```

````

Mark "Commit and prepare for PR" as completed.

## Context Throughout

Maintain issue context throughout the workflow:

- Reference issue number in commits: "Fixes #[number]"
- Keep issue requirements visible during development
- Track progress against acceptance criteria

## Error Handling

- **Issue not found**: Check issue number and repository, suggest correct format
- **Worktree creation failed**: Report error, suggest manual creation or cleanup
- **Workflow not found**: Fall back to manual development with guidance
- **Development interrupted**: Save state, allow resumption with context
- **Agent failure**:
  1. Log error to console: "Agent [agent-name] failed: [error-message]"
  2. Show user: "Agent [name] encountered an error. Offering fallback options."
  3. Present alternatives: retry, manual fallback, or skip phase

## State Preservation

If context grows large or workflow is interrupted, preserve:

```text
Essential context for Issue #[number]:
- Branch: [branch-name]
- Worktree: [path]
- Phase: [current phase]
- Key files: [list]
- Acceptance criteria: [summary]
```

Use /compact if needed, ensuring this context is maintained.
