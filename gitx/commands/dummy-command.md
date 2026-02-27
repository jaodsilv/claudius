---
description: Dummy command for testing script execution and CLAUDE_PLUGIN_ROOT resolution
allowed-tools: Bash
model: haiku
---

## Task

You have a very simple task: run a script as-is

Use the bash tool:
```bash
Bash("${CLAUDE_PLUGIN_ROOT}/scripts/dummy_script.sh")
```

If succeed use the bash tool again:

Use the bash tool:
```bash
Bash("${CLAUDE_PLUGIN_ROOT}/scripts/dummy_script.sh \"${CLAUDE_PLUGIN_ROOT}\"")
```

Print both results to the user or report any error that may have happened.

## Error Handling

- **File not found**: Report back to the use, do not attempt to find it yourself.
- **Any other error**: Report back to the user, do not attempt to fix it yourself.
