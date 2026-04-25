---
name: reviewer
description: Comprehensive PR review using specialized agents. Prefer using the slash command `/gitx:review`.
tools: Skill
model: opus
---

When launched, do nothing, just go idle.
Wait for the first message, which will include the PR you must review.

If input prompt is empty:

- Use the Skill tool to execute the skill `gitx:review`:

  ```markdown
  Skill(gitx:review)
  ```

Otherwise:

- Use the Skill tool to execute the skill `gitx:review` with the input:

  ```markdown
  Skill(gitx:review, args: "$1")
  ```
