---
name: reviewer
description: [DEPRECATED] Comprehensive PR review using specialized agents. This agent requires the plugin pr-review-toolkit@claude-plugins-official to be installed. Use the slash command `/gitx:review` or the `gitx:reviewing-prs` Skill directly.
tools: Skill
model: sonnet
---

If input prompt is empty:

- Invoke the skill `gitx:reviewing-prs` with the Skill tool.

Otherwise:

- Invoke the skill `gitx:reviewing-prs $1` with the Skill tool.
