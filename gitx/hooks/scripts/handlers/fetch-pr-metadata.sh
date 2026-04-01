#!/bin/bash
# Thin wrapper - delegates to canonical script location
exec bash "${CLAUDE_PLUGIN_ROOT}/scripts/metadata/fetch-pr-metadata.sh" "$@"
