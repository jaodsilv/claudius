#!/bin/bash
# Parse issue references from various formats
# Usage: parse-references.sh <reference>
# Output: JSON with issue_number and source_type

export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
set -uo pipefail

source "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/lib/logging.sh"

REFERENCE="${1:-}"

if [[ -z "$REFERENCE" ]]; then
  echo '{"issue_number":null,"source_type":"unknown","error":"No issue reference provided"}'
  exit 1
fi

# 1. Bare number
if [[ "$REFERENCE" =~ ^[0-9]+$ ]]; then
  echo "{\"issue_number\":$REFERENCE,\"source_type\":\"bare\"}"
  exit 0
fi

# 2. Hash prefix
if [[ "$REFERENCE" =~ ^#([0-9]+)$ ]]; then
  echo "{\"issue_number\":${BASH_REMATCH[1]},\"source_type\":\"hash\"}"
  exit 0
fi

# 3. Issue prefix
if [[ "$REFERENCE" =~ ^issue-([0-9]+)$ ]]; then
  echo "{\"issue_number\":${BASH_REMATCH[1]},\"source_type\":\"prefix\"}"
  exit 0
fi

# 4. GitHub URL
if [[ "$REFERENCE" =~ https?://github\.com/[^/]+/[^/]+/issues/([0-9]+) ]]; then
  echo "{\"issue_number\":${BASH_REMATCH[1]},\"source_type\":\"url\"}"
  exit 0
fi

# 5. Branch name (substring match)
if [[ "$REFERENCE" =~ issue-([0-9]+) ]]; then
  echo "{\"issue_number\":${BASH_REMATCH[1]},\"source_type\":\"branch\"}"
  exit 0
fi

# No match
echo "{\"issue_number\":null,\"source_type\":\"unknown\",\"error\":\"Could not parse issue reference from: $REFERENCE\"}"
exit 1
