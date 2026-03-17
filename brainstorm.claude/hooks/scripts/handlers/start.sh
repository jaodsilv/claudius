#!/bin/bash
# Handler for /brainstorm:start
# Validates topic and initializes session

log_section "Start Handler"

TOPIC=$(get_positional_arg "$ARGS" 0)
log_debug "TOPIC" "$TOPIC"

# Validate required topic
validate_required_arg "topic" "$TOPIC"

# Extract optional parameters
DEPTH=$(get_flag_value "$ARGS" "--depth" --default "normal")
OUTPUT_PATH=$(get_flag_value "$ARGS" "--output-path")
if [[ -z "$OUTPUT_PATH" ]]; then
  CWD_CONVERTED=$(echo "$CWD" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g')
  OUTPUT_PATH="${CWD_CONVERTED}/.thoughts/brainstorm"
fi

log_debug "DEPTH" "$DEPTH"
log_debug "OUTPUT_PATH" "$OUTPUT_PATH"

# Initialize session
mkdir -p "$OUTPUT_PATH"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUTPUT_PATH/session-log.md" << EOF
# Brainstorm Session Log
**Topic**: $TOPIC
**Depth**: $DEPTH
**Started**: $TIMESTAMP
**Status**: In Progress
EOF

log_info "Session initialized at $OUTPUT_PATH"

# Inject resolved values back to command
hook_output_context "Phase 0 complete. Session initialized: output_path=$OUTPUT_PATH, depth=$DEPTH, topic=$TOPIC"
exit 0
