#!/usr/bin/env bash
# Example: Proper JSON output patterns
set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"

# Pattern 1: Simple static JSON
jq -n '{"decision": "allow"}'
exit 0

# Pattern 2: JSON with string variable
# reason="Blocked by policy"
# jq -n --arg r "$reason" '{"decision": "block", "reason": $r}'
# exit 0

# Pattern 3: JSON with numeric variable
# count=42
# jq -n --argjson c "$count" '{"decision": "allow", "count": $c}'
# exit 0

# Pattern 4: Multiple variables
# tool="Bash"
# user="developer"
# jq -n --arg t "$tool" --arg u "$user" \
#     '{"decision": "allow", "tool": $t, "user": $u}'
# exit 0

# Pattern 5: Complex nested object
# jq -n \
#     --arg decision "allow" \
#     --arg tool "$TOOL_NAME" \
#     --argjson ts "$(date +%s)" \
#     '{
#         decision: $decision,
#         metadata: {
#             tool: $tool,
#             timestamp: $ts,
#             version: "1.0"
#         }
#     }'
# exit 0

# Pattern 6: Capturing command output safely
# output=$(ls -la 2>&1) || output="command failed"
# jq -n --arg out "$output" '{"decision": "allow", "output": $out}'
# exit 0
