# JSON Output Patterns

Proper JSON generation and escaping for hook responses.

## The Output Contract

PreToolUse hooks communicate via JSON on stdout using the `hookSpecificOutput` format:

```json
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Explanation"}}
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}, "metadata": {"key": "value"}}
```

**Critical**: Any non-JSON stdout before the final output corrupts the response.

## Use jq for All JSON

Never construct JSON manually:

```bash
# BAD - breaks on quotes, newlines, special chars
message="Error: File \"test.txt\" not found"
echo "{\"error\": \"$message\"}"
# Output: {"error": "Error: File "test.txt" not found"}  <- INVALID JSON

# GOOD - jq handles all escaping
jq -n --arg msg "$message" '{"error": $msg}'
# Output: {"error":"Error: File \"test.txt\" not found"}  <- Valid JSON
```

## jq Patterns

### Single Field

```bash
jq -n '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
```

### With Variables

```bash
reason="Tool blocked by policy"
jq -n --arg r "$reason" '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": $r}}'
```

### Multiple Variables

```bash
tool="Bash"
action="blocked"
jq -n --arg t "$tool" --arg a "$action" \
    '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": ($t + " " + $a)}}'
```

### Raw String Input

```bash
# --arg treats input as string (escaped)
# --argjson treats input as raw JSON (not escaped)
count=42
jq -n --argjson c "$count" '{"count": $c}'
# Output: {"count":42}  <- number, not string
```

### Complex Objects

```bash
jq -n \
    --arg tool "$TOOL_NAME" \
    --argjson timestamp "$(date +%s)" \
    '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow"
        },
        metadata: {
            tool: $tool,
            timestamp: $timestamp
        }
    }'
```

## Heredoc with jq

For complex JSON, use heredoc and pipe to jq:

```bash
reason="Passed validation"

cat <<TEMPLATE | jq -c .
{
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow"
    },
    "reason": "$reason",
    "checks": ["syntax", "security", "policy"]
}
TEMPLATE
```

**Note**: Variables in heredoc are NOT escaped. Use jq for dynamic content:

```bash
# SAFE - jq escapes the variable
user_input="Has \"quotes\" and \n newlines"
jq -n --arg input "$user_input" '{message: $input}'
```

## Capturing Command Output

Capture command output and include in JSON safely:

```bash
# Capture stdout and stderr
output=$(some_command 2>&1) || true

# Include in JSON with proper escaping
jq -n --arg out "$output" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow"
    },
    command_output: $out
}'
exit 0
```

## Multi-line Output

Handle multi-line content:

```bash
log_content=$(cat /var/log/app.log | tail -20)

# jq handles newlines correctly
jq -n --arg log "$log_content" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow"
    },
    recent_logs: $log
}'
exit 0
```

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| `echo` before JSON | Corrupts output | Remove or redirect to stderr |
| Manual escaping | Breaks on special chars | Use `jq --arg` |
| Unquoted heredoc vars | Injection risk | Use jq for dynamic content |
| Missing `-n` in jq | Expects stdin | Add `-n` for no input |
| `echo` instead of jq | No escaping | Always use jq |

## Debugging Tips

### Redirect Debug Output

```bash
# Write debug to stderr, only JSON to stdout
echo "Debug: processing $TOOL_NAME" >&2
jq -n '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
exit 0
```

### Validate JSON in Development

```bash
# Pipe output to jq for validation
./my_hook.sh | jq .
```

### Log to File

```bash
LOG_FILE="/tmp/hook_debug.log"
echo "$(date): Tool=$TOOL_NAME" >> "$LOG_FILE"
jq -n '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
exit 0
```
