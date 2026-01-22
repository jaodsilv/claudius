---
name: gitx:reviewing-prs
description: Comprehensive PR review using specialized agents. Use this skill proactively when requested to review a PR. This skill requires the plugin pr-review-toolkit@claude-plugins-official to be installed
allowed-tools: Skill, Read, Bash(script/build-review-prompt.sh:*), Bash(script/post-and-update-review.sh:*), Task
model: opus
---

## Step 0: Parse Input

The input prompt represents the worktree path.

Set `$worktree` to the input or "." if empty.

If a different input type is provided, exit with error.

## Step 0.5: Ensure Metadata Exists

Use Skill `gitx:managing-pr-metadata`:

```bash
Skill(gitx:managing-pr-metadata):
  operation: ensure
  worktree: "$worktree"
```

If returned status is `needs_fetch`:

1. Run Task(gitx:pr:metadata-fetcher) with worktree

  ```bash
  Task(gitx:pr:metadata-fetcher):
    worktree: "$worktree"
  ```

2. Retry ensure

## Step 1: Build Review Prompt

Use the Bash tool to run the build-review-prompt script:

```bash
scripts/build-review-prompt.sh "$worktree"
```

Capture the output as `$reviewPrompt`.

## Step 2: Execute Review

Use the Skill tool to run the slash command below

```markdown
/pr-review-toolkit:review-pr $reviewPrompt
```

## Step 3: Post Review and Update Metadata

Once the review is complete, run the post-and-update script:

```bash
scripts/post-and-update-review.sh "$worktree"
```
