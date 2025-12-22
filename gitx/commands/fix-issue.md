---
description: Full workflow: worktree + development + push for an issue
argument-hint: "[ISSUE]"
allowed-tools: Bash(git:*), Bash(gh:*), Read, Task, Skill, AskUserQuestion
---

# Fix Issue

Complete workflow to fix a GitHub issue: creates a worktree, delegates to a development workflow, and prepares for PR.

## Parse Arguments

From $ARGUMENTS, extract:
- Issue number (required): Can be "123", "#123", or issue URL

## Gather Issue Context

Fetch issue details:
- `gh issue view <number> --json number,title,body,labels,comments`

Extract:
- Issue number
- Issue title
- Issue description
- Labels (for determining branch type)

## Step 1: Create Worktree

Invoke the worktree creation logic:
- Use `/gitx:worktree <issue-number>` pattern
- Branch name based on issue type:
  - Bug label → `bugfix/issue-<num>-<title>`
  - Feature label → `feature/issue-<num>-<title>`
  - Default → `feature/issue-<num>-<title>`

Create worktree as sibling directory.

## Step 2: Workflow Detection

Check for available development workflows and ask user which to use:

Use AskUserQuestion:
- "How would you like to develop this fix?"
- Options:
  1. "Feature development workflow (Recommended)" - Invoke feature-dev if available
  2. "TDD workflow" - Use test-driven development approach
  3. "Manual development" - Just provide issue context and let me work
  4. "Cancel" - Abort and remove worktree

## Step 3: Delegate to Workflow

Based on user choice:

### Option 1: Feature Development Workflow
If `feature-dev:feature-dev` skill/command is available:
- Invoke with issue context:
  ```
  Issue #<number>: <title>

  Description:
  <body>

  Labels: <labels>
  ```
- Let the feature-dev workflow handle implementation

### Option 2: TDD Workflow
If `tdd-workflow` skill is available:
- Load the tdd-workflow skill
- Follow TDD phases:
  1. Write failing test
  2. Implement minimal code to pass
  3. Refactor
- Provide issue context throughout

### Option 3: Manual Development
Provide structured guidance:
1. Display issue details
2. Suggest investigation approach
3. Recommend implementation steps based on issue type
4. Stay available for questions

### Graceful Fallback
If requested workflow not available:
- Inform user: "The <workflow> workflow is not available in your setup."
- Offer alternatives or proceed with manual guidance

## Step 4: After Development

Once development is complete:

1. Run `/gitx:commit-push` to commit and push changes
2. Suggest creating PR:
   ```
   Development complete. To create a pull request:
     /gitx:pr

   Or comment on the issue with progress:
     /gitx:comment-to-issue <number> "Implementation complete, PR forthcoming"
   ```

## Context Throughout

Maintain issue context throughout the workflow:
- Reference issue number in commits
- Include "Fixes #<number>" in commit messages where appropriate
- Keep issue requirements visible during development

## Error Handling

- Issue not found: Check issue number and repository
- Worktree creation failed: Report error, suggest manual creation
- Workflow not found: Fall back to manual development with guidance
- Development interrupted: Save state, allow resumption
