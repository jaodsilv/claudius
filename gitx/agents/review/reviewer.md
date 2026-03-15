---
name: reviewer
description: [DEPRECATED] Comprehensive PR review using specialized agents. This agent requires the plugin pr-review-toolkit@claude-plugins-official to be installed. Use the slash command `/gitx:review` or the `gitx:reviewing-prs` Skill directly.
tools: Skill
model: sonnet
---

If input prompt is empty:

- Use the Skill tool to execute the skill `gitx:reviewing-prs`:

  ```markdown
  Skill(gitx:reviewing-prs)
  ```

Otherwise:

- Use the Skill tool to execute the skill `gitx:reviewing-prs` with the input:

  ```markdown
  Skill(gitx:reviewing-prs, args: "$1")
  ```
