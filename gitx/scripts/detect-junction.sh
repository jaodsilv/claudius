#!/bin/bash
set -uo pipefail
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
    target=$(readlink -f "$path" 2>/dev/null || readlink "$path")
    # Validate target was resolved
    if [ -z "$target" ]; then
        echo '{"error": "Could not resolve symlink target"}'
        exit 1
    fi
    # Escape quotes in target path
    target=$(echo "$target" | sed 's/"/\\"/g')
    echo "{\"isLink\": true, \"target\": \"$target\"}"
else
    echo '{"isLink": false}'
fi

exit 0
