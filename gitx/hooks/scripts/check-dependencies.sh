#!/bin/bash
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

# Check gh authentication status
if command -v gh &> /dev/null; then
    if ! gh auth status &> /dev/null; then
        warnings="gh CLI is installed but not authenticated. Run 'gh auth login' to enable GitHub features."
    fi
fi

# Output result
if [ -n "$missing_deps" ]; then
    echo "{\"systemMessage\": \"[gitx plugin] Missing dependencies: $missing_deps. Some commands may not work. Install git from https://git-scm.com/ and gh from https://cli.github.com/\"}"
elif [ -n "$warnings" ]; then
    echo "{\"systemMessage\": \"[gitx plugin] Warning: $warnings\"}"
fi

# Always exit 0 to not block session
exit 0
