---
name: creator
description: Adds a git worktree when needing isolated development environments. Use for parallel feature work or issue-based development.
tools: Bash(git worktree *), Bash(git branch *), Bash(gh issue *), AskUserQuestion, Skill
model: sonnet
---

## Input

From the prompt (free-form, parsed by rules):

- If prompt is a number: treated as GitHub issue number — fetches issue and uses it for branch/worktree naming
- If prompt matches branch name pattern (at most 2 slashes, no dots/spaces): used as branch name directly
- If prompt is a single word without spaces: used as worktree directory name
- Otherwise: treated as task description for branch naming

## Execution

### Parsing Input Prompt

- If input is just a number, it's an issue number, store it in `$issueNumber`
- Else if input is a string with at most 2 slashes and no dots or nor spaces, it's a branch name (e.g. `feature/new-feature`), store it in `$branch`
- Else if input is a string without spaces, it's the worktree name, to be placed in `../`, store it in `$dir`.
- Otherwise, it's a task description, store it in `$title`

### Fetching Issue (if issue number provided)

Use the Skill tool to execute the skill `gitx:managing-issues` to fetch the issue:

```markdown
Skill(gitx:managing-issues):
  issue-view.sh
  <issue-number>$issueNumber</issue-number>
  <use-case>branch-naming</use-case>
```

If it succeeds, get the title and the labels from its output. Store them in `$title` and `$labels`.
If failed, exit the operation.

### Naming the branch (if branch name not provided)

If `$branch` is not provided, use the Skill tool to execute the skill `gitx:naming-branches` to generate the branch name:

```markdown
Skill(gitx:naming-branches):
  --labels $labels
  --title $title
  --number $issueNumber
```

If it succeeds, Store its output in `$branch`.
If failed, exit the operation.

### Naming the worktree (if worktree name not provided)

If `$dir` is not provided, use the Skill tool to execute the skill `gitx:naming-worktrees` to generate worktree name candidates:

```markdown
Skill(gitx:naming-worktrees):
  --branch $branch
```

If it succeeds, store the output in `$dir`.
If failed, exit the operation.

### Creating the worktree

Use the Skill tool to execute the skill `gitx:managing-worktrees` to create the worktree:

```markdown
Skill(gitx:managing-worktrees):
  worktree-create.sh
  --dir $dir
  --branch $branch
```

## Report Success

After successful creation, report from JSON:

````markdown
## Worktree Created

- **Branch**: [branch]
- **Directory**: [directory]
- **Base**: [base_branch]
- **Issue**: #[issue_number] (if applicable)

### Next Steps

```bash
/fix-issue [directory]
```

```bash
/my-development-comand [directory]
```
````

## CRITICAL: Command Boundaries

This command MUST stop after reporting success. Do NOT:

1. Navigate to the new worktree
2. Perform any development work
3. Run any commands in the worktree
4. Start implementing any features or fixes

The user will manually navigate to the worktree.
