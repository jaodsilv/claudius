# Hook Lifecycle

Understanding when and how hooks execute in Claude Code.

## Execution Flow

```text
User Request
     |
     v
Claude Plans Tool Use
     |
     v
+------------------+
| PreToolUse Hooks |  <-- Can block, modify, or allow
+------------------+
     |
     | (if allowed)
     v
+------------------+
| Tool Execution   |
+------------------+
     |
     v
+-------------------+
| PostToolUse Hooks |  <-- Can process, log, or modify result
+-------------------+
     |
     v
Claude Processes Result
```

## Hook Locations

Hooks live in the plugin's `.claude-plugin/hooks/` directory:

```text
.claude-plugin/
  hooks/
    PreToolUse/
      my_hook.sh
      another_hook.sh
    PostToolUse/
      logging_hook.sh
    Notification/
      event_handler.sh
    Stop/
      cleanup.sh
```

## Environment Variables

Hooks receive context via environment variables:

| Variable | Description | Available In |
|----------|-------------|--------------|
| `CLAUDE_TOOL_NAME` | Name of tool being called | PreToolUse, PostToolUse |
| `CLAUDE_TOOL_INPUT` | JSON string of tool parameters | PreToolUse, PostToolUse |
| `CLAUDE_TOOL_OUTPUT` | Tool execution result | PostToolUse only |
| `CLAUDE_SESSION_ID` | Current session identifier | All hooks |
| `CLAUDE_PLUGIN_ROOT` | Plugin installation path | All hooks |

## PreToolUse Decisions

PreToolUse hooks return a decision:

| Decision | Effect |
|----------|--------|
| `allow` | Tool executes normally |
| `block` | Tool blocked, reason shown to Claude |
| `modify` | Tool parameters modified (advanced) |

```bash
# Allow
jq -n '{"decision": "allow"}'

# Block with reason
jq -n '{"decision": "block", "reason": "Operation not permitted"}'
```

## Hook Ordering

Multiple hooks in the same directory execute in **alphabetical order**:

```text
hooks/PreToolUse/
  01_logging.sh      # Runs first
  02_validation.sh   # Runs second
  99_allow.sh        # Runs last
```

**First blocking decision wins**: If any hook returns `block`, subsequent hooks do not run.

## Execution Timeout

Hooks have a default timeout (typically 30 seconds). Long-running operations should:

1. Complete quickly and return a decision
2. Spawn background processes if needed
3. Use async patterns for slow operations

```bash
#!/usr/bin/env bash
set -euo pipefail

# Quick decision
jq -n '{"decision": "allow"}'

# Background logging (doesn't block)
(echo "$(date): $CLAUDE_TOOL_NAME" >> /tmp/hook.log &)

exit 0
```

## PostToolUse Processing

PostToolUse hooks receive the tool output and can:

1. Log the result
2. Update external state
3. Modify the response (advanced)

```bash
#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_OUTPUT="${CLAUDE_TOOL_OUTPUT:-}"

# Log to file
echo "[$(date)] Tool: $TOOL_NAME" >> /tmp/tool_log.txt
echo "Output: $TOOL_OUTPUT" >> /tmp/tool_log.txt

# Return success (no modification)
jq -n '{"status": "logged"}'
exit 0
```

## Stop Hooks

Stop hooks run when:

- Session ends normally
- User explicitly stops
- Error causes session termination

Use for cleanup:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Save session state
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
echo "Session $SESSION_ID ended at $(date)" >> /tmp/sessions.log

# Cleanup temp files
rm -rf "/tmp/claude_session_$SESSION_ID" 2>/dev/null || true

exit 0
```

## Cross-Platform Considerations

| Concern | Solution |
|---------|----------|
| Shebang | Use `#!/usr/bin/env bash` |
| Line endings | Ensure LF, not CRLF |
| Path separators | Use `/` (bash normalizes on Windows) |
| Temp directory | Use `mktemp` not hardcoded paths |
| Command availability | Check with `command -v` |

```bash
#!/usr/bin/env bash
set -euo pipefail

# Cross-platform temp file
TEMP=$(mktemp)

# Check for required command
if ! command -v jq &>/dev/null; then
    echo '{"decision": "allow", "warning": "jq not available"}'
    exit 0
fi

# ... hook logic ...

rm -f "$TEMP"
jq -n '{"decision": "allow"}'
exit 0
```
