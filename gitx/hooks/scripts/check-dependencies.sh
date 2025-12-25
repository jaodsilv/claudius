#!/bin/bash
set -euo pipefail
# Check for git and gh CLI dependencies
# Returns JSON with systemMessage for warnings

missing_deps=""
warnings=""

# Check git
if ! command -v git &> /dev/null; then
    missing_deps="git"
fi

# Check gh CLI
if ! command -v gh &> /dev/null; then
    if [ -n "$missing_deps" ]; then
        missing_deps="$missing_deps, gh CLI"
    else
        missing_deps="gh CLI"
    fi
fi

# Check gh authentication status and include error details
if command -v gh &> /dev/null; then
    auth_output=$(gh auth status 2>&1)
    if [ $? -ne 0 ]; then
        # Escape special characters for JSON
        escaped_auth=$(echo "$auth_output" | tr '\n' ' ' | sed 's/"/\\"/g')
        warnings="gh CLI not authenticated: $escaped_auth. Run 'gh auth login' to enable GitHub features."
    fi
fi

# Output result
if [ -n "$missing_deps" ]; then
    echo "{\"systemMessage\": \"[gitx plugin] Missing dependencies: $missing_deps. Some commands may not work. Install git from https://git-scm.com/ and gh from https://cli.github.com/\"}"
elif [ -n "$warnings" ]; then
    echo "{\"systemMessage\": \"[gitx plugin] Warning: $warnings\"}"
else
    echo '{"status": "ok"}'
fi

# Exit 1 if critical dependency (git) is missing, exit 0 for optional deps
if echo "$missing_deps" | grep -q "git"; then
    exit 1
fi
exit 0
