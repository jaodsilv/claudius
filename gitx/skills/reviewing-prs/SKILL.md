---
name: gitx:reviewing-prs
description: Comprehensive PR review using specialized agents. Use this skill proactively when requested to review a PR. This skill requires the plugin pr-review-toolkit@claude-plugins-official to be installed
allowed-tools: Skill, Read, Bash(scripts/post-and-update-review.sh:*)
model: opus
---

## Pre-conditions

The pre-command hook has already:

1. Ensured metadata exists (fetched if needed)
2. Validated turn is REVIEW
3. Built the review prompt to `.thoughts/pr/review-prompt.txt`

## Step 1: Read Prompt and Execute Review

1. Read the prompt from `.thoughts/pr/review-prompt.txt` (relative to worktree)
2. Run the external plugin command with the prompt content:

   ```
   /pr-review-toolkit:review-pr <prompt-content>
   ```

## Step 2: Post Review and Update Metadata

Once the review is complete, run the post-and-update script:

```bash
scripts/post-and-update-review.sh "$worktree"
```

The `$worktree` path defaults to "." (current directory).

## Error Handling

**CRITICAL**: If any script fails (non-zero exit code), do NOT attempt manual fallbacks.

- Do NOT manually post the review using `gh pr comment` or `gh pr review`
- Do NOT skip the metadata update step
- Do NOT improvise alternative solutions

Instead:

1. Report the error clearly to the user
2. Use AskUserQuestion to ask the user how to proceed:
   - "Retry the failed step"
   - "Abort the review process"
   - "Let me handle it manually"
