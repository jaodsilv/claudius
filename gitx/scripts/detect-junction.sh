#!/bin/bash
set -euo pipefail
# Detect if a path is a symlink and return its target
# Usage: detect-junction.sh <path>
# Output: JSON { "isLink": true/false, "target": "path" }

path="$1"

if [ -z "$path" ]; then
    echo '{"error": "No path provided"}'
    exit 1
fi

if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    echo '{"error": "Path does not exist"}'
    exit 1
fi

if [ -L "$path" ]; then
    # Capture errors from readlink commands for diagnostics
    if ! target=$(readlink -f "$path" 2>&1); then
        first_error="$target"
        if ! target=$(readlink "$path" 2>&1); then
            # Both commands failed - include error details
            escaped_error=$(echo "$first_error" | sed 's/"/\\"/g')
            echo "{\"error\": \"Could not resolve symlink target: $escaped_error\"}"
            exit 1
        fi
    fi
    # Validate target was resolved
    if [ -z "$target" ]; then
        echo '{"error": "Could not resolve symlink target: empty result"}'
        exit 1
    fi
    # Escape quotes in target path
    target=$(echo "$target" | sed 's/"/\\"/g')
    echo "{\"isLink\": true, \"target\": \"$target\"}"
else
    echo '{"isLink": false}'
fi

exit 0
