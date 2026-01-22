#!/usr/bin/env bash
# gitignore-add.sh - Add patterns to .gitignore with validation
#
# Usage: gitignore-add.sh <patterns...> [options]
#   patterns: One or more patterns to add to .gitignore
#
# Options:
#   --execute           Actually add the patterns (default: validate only)
#   --untrack           Also run git rm --cached for tracked files
#
# Exit codes:
#   0 - Success (or validation passed)
#   1 - Tracked file conflict (needs user decision)
#   2 - Error (invalid pattern, no repo, etc.)
#
# Output: JSON with validation results and operation status

set -euo pipefail

# === Helper Functions ===
json_output() {
    local status="$1"
    local exit_code="$2"
    shift 2

    echo "{"
    echo "  \"status\": \"$status\","
    echo "  \"exit_code\": $exit_code,"
    echo "  $*"
    echo "}"
}

error_output() {
    local code="$1"
    local message="$2"
    json_output "error" 2 "\"error_code\": \"$code\", \"message\": \"$message\""
    exit 2
}

# Validate gitignore pattern syntax
validate_pattern() {
    local pattern="$1"

    # Empty pattern
    if [[ -z "$pattern" ]]; then
        echo "empty"
        return
    fi

    # Comment (starts with #)
    if [[ "$pattern" =~ ^# ]]; then
        echo "comment"
        return
    fi

    # Check for dangerous patterns
    if [[ "$pattern" == "/" || "$pattern" == "/*" || "$pattern" == "**" ]]; then
        echo "dangerous"
        return
    fi

    # Valid pattern
    echo "valid"
}

# Check if pattern already exists in .gitignore
pattern_exists() {
    local pattern="$1"
    local gitignore="$2"

    if [[ ! -f "$gitignore" ]]; then
        return 1
    fi

    # Exact match (ignoring leading/trailing whitespace)
    grep -qxF "$pattern" "$gitignore" 2>/dev/null
}

# Find tracked files that match a pattern
find_tracked_matches() {
    local pattern="$1"

    # Use git ls-files to find tracked files matching the pattern
    git ls-files -- "$pattern" 2>/dev/null || true
}

# === Argument Parsing ===
PATTERNS=()
EXECUTE=false
UNTRACK=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --execute)
            EXECUTE=true
            shift
            ;;
        --untrack)
            UNTRACK=true
            shift
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            PATTERNS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#PATTERNS[@]} -eq 0 ]]; then
    error_output "no_patterns" "No patterns specified. Usage: gitignore-add.sh <patterns...> [options]"
fi

# === Find Repository Root ===
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_ROOT" ]]; then
    error_output "not_a_repo" "Not in a git repository."
fi

GITIGNORE="$REPO_ROOT/.gitignore"

# === Validate Patterns ===
VALID_PATTERNS=()
EXISTING_PATTERNS=()
INVALID_PATTERNS=()
TRACKED_CONFLICTS=()

for pattern in "${PATTERNS[@]}"; do
    validation=$(validate_pattern "$pattern")

    case "$validation" in
        "empty")
            continue
            ;;
        "comment")
            continue
            ;;
        "dangerous")
            INVALID_PATTERNS+=("$pattern: dangerous pattern that would ignore too much")
            continue
            ;;
        "valid")
            ;;
    esac

    # Check if already in .gitignore
    if pattern_exists "$pattern" "$GITIGNORE"; then
        EXISTING_PATTERNS+=("$pattern")
        continue
    fi

    # Check for tracked file conflicts
    tracked_files=$(find_tracked_matches "$pattern")
    if [[ -n "$tracked_files" ]]; then
        # Store as "pattern:file1,file2,..."
        files_list=$(echo "$tracked_files" | tr '\n' ',' | sed 's/,$//')
        TRACKED_CONFLICTS+=("$pattern:$files_list")
    fi

    VALID_PATTERNS+=("$pattern")
done

# === Build JSON Arrays ===
build_json_array() {
    local arr=("$@")
    local result="["
    local first=true

    for item in "${arr[@]}"; do
        if $first; then
            first=false
        else
            result+=", "
        fi
        result+="\"$item\""
    done

    result+="]"
    echo "$result"
}

VALID_JSON=$(build_json_array "${VALID_PATTERNS[@]}")
EXISTING_JSON=$(build_json_array "${EXISTING_PATTERNS[@]}")
INVALID_JSON=$(build_json_array "${INVALID_PATTERNS[@]}")

# Build tracked conflicts as array of objects
CONFLICTS_JSON="["
first=true
for conflict in "${TRACKED_CONFLICTS[@]}"; do
    if $first; then
        first=false
    else
        CONFLICTS_JSON+=", "
    fi
    pattern="${conflict%%:*}"
    files="${conflict#*:}"
    CONFLICTS_JSON+="{\"pattern\": \"$pattern\", \"files\": \"$files\"}"
done
CONFLICTS_JSON+="]"

# === Info Mode (default) ===
if [[ "$EXECUTE" != "true" ]]; then
    HAS_CONFLICTS=false
    if [[ ${#TRACKED_CONFLICTS[@]} -gt 0 && "$UNTRACK" != "true" ]]; then
        HAS_CONFLICTS=true
    fi

    if [[ "$HAS_CONFLICTS" == "true" ]]; then
        json_output "needs_confirmation" 1 \
            "\"gitignore_path\": \"$GITIGNORE\"," \
            "\"valid_patterns\": $VALID_JSON," \
            "\"existing_patterns\": $EXISTING_JSON," \
            "\"invalid_patterns\": $INVALID_JSON," \
            "\"tracked_conflicts\": $CONFLICTS_JSON," \
            "\"untrack_requested\": $UNTRACK"
        exit 1
    else
        json_output "ready" 0 \
            "\"gitignore_path\": \"$GITIGNORE\"," \
            "\"valid_patterns\": $VALID_JSON," \
            "\"existing_patterns\": $EXISTING_JSON," \
            "\"invalid_patterns\": $INVALID_JSON," \
            "\"tracked_conflicts\": $CONFLICTS_JSON," \
            "\"untrack_requested\": $UNTRACK"
        exit 0
    fi
fi

# === Execute Mode ===

if [[ ${#VALID_PATTERNS[@]} -eq 0 ]]; then
    json_output "no_changes" 0 \
        "\"message\": \"No new patterns to add. All patterns either already exist or are invalid.\"," \
        "\"existing_patterns\": $EXISTING_JSON," \
        "\"invalid_patterns\": $INVALID_JSON"
    exit 0
fi

# Track what we did
ADDED_PATTERNS=()
UNTRACKED_FILES=()

# Step 1: Untrack files if requested
if [[ "$UNTRACK" == "true" && ${#TRACKED_CONFLICTS[@]} -gt 0 ]]; then
    for conflict in "${TRACKED_CONFLICTS[@]}"; do
        pattern="${conflict%%:*}"
        files="${conflict#*:}"

        # Untrack each file
        IFS=',' read -ra file_array <<< "$files"
        for file in "${file_array[@]}"; do
            if [[ -n "$file" ]]; then
                git rm --cached "$file" 2>/dev/null || true
                UNTRACKED_FILES+=("$file")
            fi
        done
    done
fi

# Step 2: Add patterns to .gitignore
# Ensure file ends with newline if it exists
if [[ -f "$GITIGNORE" ]]; then
    # Check if file ends with newline
    if [[ -s "$GITIGNORE" ]] && [[ "$(tail -c1 "$GITIGNORE" | wc -l)" -eq 0 ]]; then
        echo "" >> "$GITIGNORE"
    fi
fi

for pattern in "${VALID_PATTERNS[@]}"; do
    echo "$pattern" >> "$GITIGNORE"
    ADDED_PATTERNS+=("$pattern")
done

# Build result arrays
ADDED_JSON=$(build_json_array "${ADDED_PATTERNS[@]}")
UNTRACKED_JSON=$(build_json_array "${UNTRACKED_FILES[@]}")

json_output "success" 0 \
    "\"gitignore_path\": \"$GITIGNORE\"," \
    "\"added_patterns\": $ADDED_JSON," \
    "\"untracked_files\": $UNTRACKED_JSON," \
    "\"existing_skipped\": $EXISTING_JSON," \
    "\"invalid_skipped\": $INVALID_JSON"
