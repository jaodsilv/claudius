# Error Handling Rules

Detailed patterns for robust error handling in Claude Code hooks.

## The Exit Code Contract

| Exit Code | Meaning | Claude Behavior |
|-----------|---------|-----------------|
| 0 | Success | Processes JSON output normally |
| Non-zero | Error | Hook considered failed, may retry or abort |

**Critical**: Scripts without explicit `exit 0` inherit the exit code of the last command.

## Set Strict Mode

Always start with strict mode:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

| Flag | Effect |
|------|--------|
| `-e` | Exit on any command failure |
| `-u` | Error on undefined variables |
| `-o pipefail` | Pipeline fails if any command fails |

## Handle Expected Errors

When a command might fail but should not abort:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Method 1: Conditional check
if ! result=$(some_command 2>&1); then
    jq -n --arg err "$result" '{"decision": "allow", "warning": $err}'
    exit 0
fi

# Method 2: Or-clause fallback
result=$(risky_command 2>&1) || result="fallback_value"

# Method 3: Explicit error handling
set +e
output=$(may_fail_command 2>&1)
status=$?
set -e

if [[ $status -ne 0 ]]; then
    jq -n --arg err "$output" '{"decision": "block", "reason": $err}'
    exit 0
fi
```

## Environment Variable Defaults

Always provide defaults for optional environment variables:

```bash
# BAD - fails if unset (with -u flag)
echo "$CLAUDE_TOOL_NAME"

# GOOD - default to empty string
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# GOOD - default to specific value
LOG_LEVEL="${LOG_LEVEL:-info}"
```

## Trap for Cleanup

Use trap to ensure cleanup on any exit:

```bash
#!/usr/bin/env bash
set -euo pipefail

TEMP_FILE=""

cleanup() {
    [[ -n "$TEMP_FILE" && -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"
}
trap cleanup EXIT

TEMP_FILE=$(mktemp)
# ... use temp file ...

# Cleanup happens automatically on any exit
jq -n '{"decision": "allow"}'
exit 0
```

## Error Recovery Pattern

Complete pattern for error-resilient hooks:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Trap for unexpected errors
trap 'jq -n "{\"decision\": \"allow\", \"error\": \"Unexpected failure\"}" && exit 0' ERR

# Safe variable access
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-{}}"

# Protected command execution
if result=$(validate_tool "$TOOL_NAME" 2>&1); then
    jq -n --arg r "$result" '{"decision": "allow", "note": $r}'
else
    jq -n --arg r "$result" '{"decision": "allow", "warning": $r}'
fi

exit 0
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Missing `exit 0` | Last command exit code used | Always end with `exit 0` |
| Unquoted variables | Word splitting, glob expansion | Always quote: `"$VAR"` |
| Undefined variables | Script aborts with `-u` | Use defaults: `${VAR:-}` |
| Uncaught errors | Non-zero exit | Use trap or conditionals |
| Stderr leakage | Contaminates JSON output | Redirect: `2>/dev/null` or `2>&1` |
