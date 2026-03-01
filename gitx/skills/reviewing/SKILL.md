---
description: Comprehensive PR review using specialized agents. Use this skill proactively when requested to review a PR. This skill requires the plugin pr-review-toolkit@claude-plugins-official to be installed
argument-hint: "[[--worktree] <worktree>]"
allowed-tools: Skill, Read, Bash
context: fork
model: opus
---

## Step 0: Hook Additional Context Parsing

IGNORE arguments. Instead, parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`
- `review-prompt`: store its value in `$review-prompt`, keep it raw, no need to remove the escaping.

## Step 1: Read Prompt and Execute Review

Use the skill tool to RUN the external plugin command with the prompt content:

```markdown
Skill(/pr-review-toolkit:review-pr $review-prompt)
```

## Step 2: Post Review and Update Metadata

Once the review is complete, Use the bash tool to run the post-and-update script:

```markdown
Bash(${CLAUDE_PLUGIN_ROOT}/scripts/comments/post-and-update-review.sh "$worktree")
```

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
