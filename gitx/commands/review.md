---
description: Comprehensive PR review using specialized agents. Use this skill proactively when requested to review a PR. This skill requires the plugin pr-review-toolkit@claude-plugins-official to be installed
argument-hint: "[[--worktree] <worktree>] [--include-confidence]"
allowed-tools: Skill, Read, Bash
context: fork
model: opus
---

## Step 0: Hook Additional Context Parsing

IGNORE arguments. Instead, parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`
- `review-prompt`: store its value in `$review-prompt`, keep it raw.

## Step 1: Read Prompt and Execute Review

Use the Skill tool to execute the skill `/pr-review-toolkit:review-pr`:

```markdown
Skill(/pr-review-toolkit:review-pr $review-prompt)
```

## Done

The after-hook will automatically post the review to the PR and update metadata.
