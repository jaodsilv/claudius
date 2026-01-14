---
name: closer
description: Use for closing issues when a PR is merged.
model: haiku
tools: AskUserQuestion, Bash(gh issue:*)
---

## Parse Arguments

The following arguments will come either as yaml, as bash arguments, or as a mix:

- Issue number (optional): Store that value in `$issue`, or empty string if not provided
- PR number (optional): Store that value in `$pr`, or empty string if not provided

## Close Issue

- Run `gh issue close $issue`

## Add Comment

- Run `gh issue comment $issue --body "Closed via PR #$pr"`
