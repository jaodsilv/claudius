---

allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
description: Adds a data repository to an existing project
argument-hint: project-name: <project-name>

---

## Context

- Arguments: <arguments>$ARGUMENTS</arguments>
- Purpose: <purpose>Add an encrypted data repository to an existing project and link it to all worktrees.</purpose>

## Execution

Follow the instructions described in the numbered list below:

1. Parse arguments considering it as a yaml object and assign its values to variables of the same names
2. Validate that `$project-name` is provided, if not ask user for it
3. Verify that the project exists at `D:/src/$project-name/`
4. Execute the following steps:

### Step 1: Create Data Repository on GitHub

```bash
gh repo create $project-name-data --private
```

### Step 2: Clone Data Repository

```bash
gh repo clone $project-name-data D:/src/$project-name/data
```

### Step 3: Initialize git-crypt in Data Repository

```bash
cd D:/src/$project-name/data && git-crypt init
```

### Step 4: Find Existing Worktrees

Scan `D:/src/$project-name/` for existing worktrees (directories that are git repositories but NOT the `data` folder):

```bash
ls D:/src/$project-name/
```

For each directory found (excluding `data`):
1. Check if it's a git repository
2. Check if it already has a `data` folder/junction
3. If no `data` folder exists, create a junction

### Step 5: Create Junction Links for Each Worktree

For each worktree `$worktree-name` found in Step 4 that doesn't have a data folder:

```cmd
mklink /J D:/src/$project-name/$worktree-name/data D:/src/$project-name/data
```

### Step 6: Update .gitignore in Each Worktree

For each worktree, ensure `data/` is in the `.gitignore`:

```bash
cd D:/src/$project-name/$worktree-name
grep -q "^data/$" .gitignore || echo "data/" >> .gitignore
```

### Step 7: Report Success

Report to user:
- Data repository created at: `D:/src/$project-name/data`
- git-crypt initialized
- List of worktrees that were linked
- Reminder to commit .gitignore changes if any were made

## Parameters

### Parameters Schema

```yaml
project-create-data-arguments:
  type: object
  description: Arguments for the command /project:create-data
  properties:
    project-name:
      type: string
      description: Name of the existing project
  required:
    - project-name
```

## Usage Examples

### Add data repo to existing project

```yaml
/project:create-data project-name: my-existing-project
```
