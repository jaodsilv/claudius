---
name: cc:configuring-hooks
description: >-
  Configures Claude Code plugin hooks with proper error handling, JSON output,
  and lifecycle patterns. Use when creating PreToolUse, PostToolUse, or other
  hooks. Covers exit codes, output capture, and cross-platform scripting.
version: 1.0.0
allowed-tools: Read
model: sonnet
---

# Configuring Hooks

Best practices for writing Claude Code plugin hooks that intercept tool calls.

## Quick Reference Checklist

Before publishing a hook, verify:

- [ ] Script has `#!/usr/bin/env bash` shebang
- [ ] Uses `set -euo pipefail` for error handling
- [ ] JSON output uses proper escaping with `jq`
- [ ] Script ends with explicit `exit 0`
- [ ] Captured output does not corrupt JSON
- [ ] Tested on target platforms (Windows/macOS/Linux)

## Hook Types

| Hook | Fires | Use Cases |
|------|-------|-----------|
| PreToolUse | Before tool execution | Block, modify, or log tool calls |
| PostToolUse | After tool returns | Process results, update state |
| Notification | On events | Respond to session events |
| Stop | On explicit stop | Cleanup, save state |

## Critical Rules

### 1. Always Use Explicit Exit

Every hook MUST end with `exit 0` for success:

```bash
#!/usr/bin/env bash
set -euo pipefail

# ... hook logic ...

# REQUIRED: Explicit exit
exit 0
```

**Why**: Without explicit exit, the script may return non-zero from the last command, causing Claude to interpret it as a hook failure.

### 2. Capture Output Properly

Any stdout before JSON corrupts the response:

```bash
# BAD - echo corrupts JSON
echo "Processing..."
cat <<EOF
{"decision": "allow"}
EOF

# GOOD - capture to variable, output only JSON
result=$(some_command 2>&1)
cat <<EOF
{"decision": "allow", "log": "$result"}
EOF
exit 0
```

### 3. Use jq for JSON Escaping

Never manually escape JSON strings:

```bash
# BAD - manual escaping breaks on special chars
message="User said: \"hello\""
echo "{\"message\": \"$message\"}"

# GOOD - jq handles all escaping
message="User said: \"hello\""
jq -n --arg msg "$message" '{"message": $msg}'
exit 0
```

## PreToolUse Hook Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Access tool info via environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Decision logic
if [[ "$TOOL_NAME" == "Bash" ]]; then
    # Block with reason
    jq -n '{"decision": "block", "reason": "Bash disabled"}'
    exit 0
fi

# Allow by default
jq -n '{"decision": "allow"}'
exit 0
```

## Reference Navigation

Read reference files based on your task:

| Task | Reference File |
|------|----------------|
| Error handling patterns | [references/error-handling-rules.md](references/error-handling-rules.md) |
| JSON output and escaping | [references/json-output-patterns.md](references/json-output-patterns.md) |
| Hook execution lifecycle | [references/hook-lifecycle.md](references/hook-lifecycle.md) |

## Example Files

Working examples for common patterns:

| Pattern | Example File |
|---------|--------------|
| Error handling | [examples/error-handling.sh](examples/error-handling.sh) |
| JSON output | [examples/json-output.sh](examples/json-output.sh) |
| Capture and log | [examples/capture-and-log.sh](examples/capture-and-log.sh) |
| Complete PreToolUse | [examples/complete-pretooluse-hook.sh](examples/complete-pretooluse-hook.sh) |
