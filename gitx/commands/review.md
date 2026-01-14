---
description: Comprehensive PR review using specialized agents. This agent requires the plugin pr-review-toolkit@claude-plugins-official to be installed
argument-hint: "[PR_NUMBER]"
allowed-tools: Task
model: haiku
---

Use the Task tool to start the agent `gitx:review:reviewer` with the `$ARGUMENTS` value as prompt
