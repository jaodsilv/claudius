---

allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
description: Creates a new project with paired data repository
argument-hint: project-name: <project-name> visibility: <private|public>

---

## Context

- Arguments: <arguments>$ARGUMENTS</arguments>
- Purpose: <purpose>Initialize a new project with a main repository and a paired encrypted data repository.</purpose>

## Execution

Follow the instructions described in the numbered list below:

1. Parse arguments considering it as a yaml object and assign its values to variables of the same names
2. Set default values:
   - `$visibility` defaults to `private` if not provided
3. Validate that `$project-name` is provided, if not ask user for it
4. Execute the following steps:

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

### Step 1: Create Main Repository

```bash
gh repo create $project-name --$visibility
```

### Step 2: Create Data Repository

```bash
gh repo create $project-name-data --$visibility
```

### Step 3: Create Project Directory Structure

```bash
mkdir -p D:/src/$project-name
```

### Step 4: Clone Main Repository

```bash
gh repo clone $project-name D:/src/$project-name/main
```

### Step 5: Clone Data Repository

```bash
gh repo clone $project-name-data D:/src/$project-name/data
```

### Step 6: Initialize git-crypt in Data Repository

```bash
cd D:/src/$project-name/data && git-crypt init
```

### Step 7: Create Junction Link

```cmd
mklink /J D:/src/$project-name/main/data D:/src/$project-name/data
```

### Step 8: Update Main Repository .gitignore

Add `data/` to the `.gitignore` file in the main repository (idempotent - only adds if not already present):

```bash
grep -q "^data/$" D:/src/$project-name/main/.gitignore || echo "data/" >> D:/src/$project-name/main/.gitignore
```

### Step 9: Commit .gitignore Change

```bash
cd D:/src/$project-name/main && git add .gitignore && git commit -m "chore: add data folder to gitignore"
```

### Step 10: Report Success

Report to user:
- Main repository created at: `D:/src/$project-name/main`
- Data repository created at: `D:/src/$project-name/data`
- Junction link created: `D:/src/$project-name/main/data` → `D:/src/$project-name/data`
- git-crypt initialized in data repository

## Parameters

### Parameters Schema

```yaml
project-create-arguments:
  type: object
  description: Arguments for the command /project:create
  properties:
    project-name:
      type: string
      description: Name of the project (used for both repos)
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

### Create a private project

```yaml
/project:create project-name: my-new-project
```

### Create a public project

```yaml
/project:create project-name: my-open-source-project visibility: public
```
