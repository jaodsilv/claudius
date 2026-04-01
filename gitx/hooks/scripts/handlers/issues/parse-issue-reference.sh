#!/bin/bash
# Handler for /gitx:parse-issue-reference command
# Parses issue reference and blocks (no LLM needed), injecting result as context

source "$SCRIPTS_DIR/lib/hook-output.sh"

log_section "Parse-Issue-Reference Handler"
log_debug "ARGS" "$ARGS"

# Extract the reference from args (first non-flag argument)
REFERENCE="$ARGS"

# Call the canonical parse script
PARSE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/issues/parse-references.sh"
if [[ ! -f "$PARSE_SCRIPT" ]]; then
  log_error "parse-references.sh not found"
  echo "Error: parse-references.sh not found" >&2
  exit 2
fi

RESULT=$(bash "$PARSE_SCRIPT" "$REFERENCE" 2>/dev/null)
EXIT_CODE=$?
log_debug "RESULT" "$RESULT"

if [[ $EXIT_CODE -eq 0 ]]; then
  log_info "Parse successful"
  log_exit 0 "block with result"
  hook_output_block "$RESULT"
  exit 0
else
  log_error "Parse failed: $RESULT"
  log_exit 2 "parse failed"
  echo "Error: $RESULT" >&2
  exit 2
fi
