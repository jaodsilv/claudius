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
2. Set default values:
   1. `$visibility` defaults to `private` if not provided
3. Validate that `$project-name` is provided, if not ask user for it
4. Verify that the project exists at `D:/src/$project-name/`
5. Execute the following steps:

### Prerequisites

Before proceeding, verify that all required tools are installed and properly configured:

#### Check 1: Verify git-crypt Installation

```bash
git-crypt --version
```

If git-crypt is not installed:
1. On Windows: Install via Chocolatey (`choco install git-crypt`)
2. On macOS: Install via Homebrew (`brew install git-crypt`)
3. On Linux: Install via package manager (`sudo apt-get install git-crypt`)

#### Check 2: Verify gh CLI Authentication

```bash
gh auth status
```

If not authenticated:
1. Run `gh auth login` to authenticate with GitHub
2. Follow the prompts to complete authentication

#### Error Handling

If either check fails, do NOT proceed. Install the missing tool or complete authentication first.

### Step 1: Create Data Repository on GitHub

```bash
gh repo create $project-name-data --$visibility
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

Use the Glob tool to scan `D:/src/$project-name/` for directories (worktrees), then filter for git repositories:

1. Use Glob to find all directories at `D:/src/$project-name/`:
   1. Pattern: `$project-name/*` (with glob parameter `path: D:/src`)
   2. Returns all top-level directories in the project folder

2. For each directory found by Glob (excluding `data`):
   1. Check if it's a git repository by verifying `.git` directory exists
   2. Check if it already has a `data` folder/junction
   3. If no `data` folder exists, mark it for Step 5 (junction creation)

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
    visibility:
      type: string
      enum:
        - private
        - public
      description: Repository visibility (default: private)
  required:
    - project-name
```

### Default Parameters Values

```yaml
arguments-defaults:
  visibility: private
```

## Usage Examples

### Add data repo to existing project

```yaml
/project:create-data project-name: my-existing-project
```

### Add data repo with public visibility

```yaml
/project:create-data project-name: my-open-source-project visibility: public
```
