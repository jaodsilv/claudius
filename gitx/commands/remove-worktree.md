---
description: Remove worktree, branch, and optionally remote branch
argument-hint: "[NAME] [-f force] [-r remove-remote]"
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git push:*), Bash(git switch:*), Bash(bash:*), Bash(powershell:*), AskUserQuestion
---

# Remove Worktree

Remove a git worktree along with its branch, with option to also remove the remote branch.

**IMPORTANT**: Before removing, check for junction points/symlinks that point outside the repository to prevent data loss.

## Parse Arguments

From $ARGUMENTS, extract:
- Worktree name/path (positional, or current directory if not provided)
- `-f` or `--force`: Force removal even with uncommitted changes
- `-r` or `--remove-remote`: Also delete the remote branch

## Gather Context

Get worktree information:
- List all worktrees: !`git worktree list`
- Current directory: !`pwd`
- Repository root: !`git rev-parse --show-toplevel`

Identify the target worktree:
- If name provided: Find matching worktree by name or path
- If no name: Use current directory if it's a worktree (not main)

Get branch associated with worktree:
- Parse `git worktree list` output to find branch name

## Junction/Symlink Detection

**Critical Step**: Before removing the worktree, scan for junction points or symlinks that point outside the repository.

Detect platform and check for junctions:
- Platform: !`uname -s 2>/dev/null || echo "Windows"`

For each item in the worktree directory that might be a junction/symlink:
1. Check common junction locations (e.g., `data/`, `node_modules/`, `.env` folders)
2. Use appropriate detection script:
   - Unix: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-junction.sh" <path>`
   - Windows: `powershell -File "${CLAUDE_PLUGIN_ROOT}/scripts/detect-junction.ps1" <path>`

If junctions found pointing outside the worktree:
1. List them to the user
2. Ask for confirmation before proceeding
3. Remove junctions FIRST before removing worktree

## Confirmation

Use AskUserQuestion to confirm the destructive action:

Show what will be deleted:
- Worktree path
- Local branch name
- Remote branch (if -r flag)
- Any detected junctions (and their targets)

Options:
1. "Delete worktree and branch" - proceed
2. "Delete worktree only" - keep branch
3. "Cancel" - abort

If junctions detected, add warning:
"WARNING: Found junction/symlink pointing to external directory. The junction will be removed (not the target directory)."

## Removal Process

Execute in order:

### Step 1: Remove junctions (if any)

For each junction pointing outside:
- Windows: `cmd /c rmdir <junction-path>`
- Unix: `rm <symlink-path>` (removes link, not target)

### Step 2: Check for uncommitted changes

If not forcing:
- Run `git -C <worktree-path> status --porcelain`
- If changes exist: warn and abort (or proceed if -f)

### Step 3: Switch away if currently in worktree

- If current directory is the worktree: `cd` to main worktree first

### Step 4: Remove worktree

- Standard: `git worktree remove <worktree-path>`
- Force: `git worktree remove --force <worktree-path>`

### Step 5: Delete local branch

- Standard: `git branch -d <branch-name>`
- Force: `git branch -D <branch-name>`

### Step 6: Delete remote branch (if -r flag)

- `git push origin --delete <branch-name>`

## Report Results

Summarize what was removed:
- Worktree path: removed
- Local branch: removed
- Remote branch: removed (if -r) or "still exists on remote"
- Junctions: listed any that were removed

## Error Handling

1. Worktree not found: List available worktrees.
2. Branch has unmerged changes: Warn and require -f flag.
3. Remote branch doesn't exist: Note but continue.
4. Permission denied on junction: Report and suggest manual removal.
