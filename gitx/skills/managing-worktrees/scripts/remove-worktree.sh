#!/usr/bin/env bash
# remove-worktree.sh - Remove a git worktree and optionally its branch
#
# Usage: remove-worktree.sh <worktree> [options]
#   worktree: Path or name of the worktree to remove
#
# Options:
#   -f, --force         Force removal even with uncommitted changes
#   -r, --remove-remote Delete remote branch after local removal
#   --execute           Actually perform the removal (default: info only)
#
# Exit codes:
#   0 - Success (or info output)
#   1 - Has uncommitted changes (needs user decision)
#   2 - Error (worktree not found, etc.)
#
# Output: JSON with worktree info and operation results

set -euo pipefail

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Check for junctions/symlinks in worktree
detect_junctions() {
    local worktree_path="$1"
    local junctions=()

    # On Windows with Git Bash, check for junctions using cmd
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                junctions+=("$line")
            fi
        done < <(find "$worktree_path" -maxdepth 3 -type l 2>/dev/null || true)
    else
        # On Unix, just find symlinks
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                junctions+=("$line")
            fi
        done < <(find "$worktree_path" -maxdepth 3 -type l 2>/dev/null || true)
    fi

    printf '%s\n' "${junctions[@]}"
}

# Remove junctions/symlinks before worktree removal
remove_junctions() {
    local worktree_path="$1"

    while IFS= read -r junction; do
        if [[ -n "$junction" ]]; then
            if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* ]]; then
                # On Windows, use rmdir for junctions
                cmd //c "rmdir \"$(cygpath -w "$junction")\"" 2>/dev/null || rm -f "$junction"
            else
                rm -f "$junction"
            fi
        fi
    done < <(detect_junctions "$worktree_path")
}

# === Argument Parsing ===
WORKTREE=""
FORCE=false
REMOVE_REMOTE=false
EXECUTE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        -r|--remove-remote)
            REMOVE_REMOTE=true
            shift
            ;;
        --execute)
            EXECUTE=true
            shift
            ;;
        -*)
            error_output "unknown_option" "Unknown option: $1"
            ;;
        *)
            if [[ -z "$WORKTREE" ]]; then
                WORKTREE="$1"
            else
                error_output "too_many_args" "Too many arguments. Expected one worktree path."
            fi
            shift
            ;;
    esac
done

if [[ -z "$WORKTREE" ]]; then
    error_output "missing_worktree" "No worktree specified. Usage: remove-worktree.sh <worktree> [options]"
fi

# === Find Worktree ===
# Get list of worktrees and find the matching one
WORKTREE_INFO=$(git worktree list --porcelain 2>/dev/null || true)

if [[ -z "$WORKTREE_INFO" ]]; then
    error_output "no_worktrees" "No worktrees found in this repository."
fi

# Find worktree by path (exact match or basename match)
WORKTREE_PATH=""
WORKTREE_BRANCH=""
WORKTREE_COMMIT=""

# Normalize input path
if [[ -d "$WORKTREE" ]]; then
    WORKTREE=$(cd "$WORKTREE" && pwd)
fi

# Parse worktree list
while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
        current_path="${BASH_REMATCH[1]}"
        current_branch=""
        current_commit=""
    elif [[ "$line" =~ ^HEAD\ (.+)$ ]]; then
        current_commit="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
        current_branch="${BASH_REMATCH[1]}"
    elif [[ -z "$line" ]]; then
        # End of worktree entry - check if it matches
        if [[ "$current_path" == "$WORKTREE" ]] || [[ "$(basename "$current_path")" == "$WORKTREE" ]]; then
            WORKTREE_PATH="$current_path"
            WORKTREE_BRANCH="$current_branch"
            WORKTREE_COMMIT="$current_commit"
            break
        fi
    fi
done <<< "$WORKTREE_INFO"

# Check final entry if no blank line at end
if [[ -z "$WORKTREE_PATH" ]]; then
    if [[ "$current_path" == "$WORKTREE" ]] || [[ "$(basename "$current_path")" == "$WORKTREE" ]]; then
        WORKTREE_PATH="$current_path"
        WORKTREE_BRANCH="$current_branch"
        WORKTREE_COMMIT="$current_commit"
    fi
fi

if [[ -z "$WORKTREE_PATH" ]]; then
    error_output "worktree_not_found" "Worktree '$WORKTREE' not found. Use 'git worktree list' to see available worktrees."
fi

# === Check for Main Worktree ===
MAIN_WORKTREE=$(git worktree list --porcelain | grep -A0 "^worktree " | head -1 | sed 's/^worktree //')
if [[ "$WORKTREE_PATH" == "$MAIN_WORKTREE" ]]; then
    error_output "main_worktree" "Cannot remove the main worktree. Use a regular worktree path."
fi

# === Check for Uncommitted Changes ===
HAS_CHANGES=false
CHANGES_SUMMARY=""

if [[ -d "$WORKTREE_PATH" ]]; then
    pushd "$WORKTREE_PATH" > /dev/null

    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l)
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

    if [[ "$STAGED" -gt 0 || "$UNSTAGED" -gt 0 || "$UNTRACKED" -gt 0 ]]; then
        HAS_CHANGES=true
        CHANGES_SUMMARY="staged: $STAGED, unstaged: $UNSTAGED, untracked: $UNTRACKED"
    fi

    popd > /dev/null
fi

# === Detect Junctions ===
JUNCTIONS_JSON="[]"
if [[ -d "$WORKTREE_PATH" ]]; then
    JUNCTION_LIST=$(detect_junctions "$WORKTREE_PATH")
    if [[ -n "$JUNCTION_LIST" ]]; then
        JUNCTIONS_JSON="["
        first=true
        while IFS= read -r j; do
            if [[ -n "$j" ]]; then
                if $first; then
                    first=false
                else
                    JUNCTIONS_JSON+=", "
                fi
                JUNCTIONS_JSON+="\"$j\""
            fi
        done <<< "$JUNCTION_LIST"
        JUNCTIONS_JSON+="]"
    fi
fi

# === Check Remote Branch Exists ===
REMOTE_BRANCH_EXISTS=false
if [[ -n "$WORKTREE_BRANCH" ]]; then
    if git ls-remote --exit-code --heads origin "$WORKTREE_BRANCH" >/dev/null 2>&1; then
        REMOTE_BRANCH_EXISTS=true
    fi
fi

# === Info Mode (default) ===
if [[ "$EXECUTE" != "true" ]]; then
    # Output info for confirmation
    if [[ "$HAS_CHANGES" == "true" && "$FORCE" != "true" ]]; then
        # Exit 1 - needs user decision
        json_output "needs_confirmation" 1 \
            "\"worktree_path\": \"$WORKTREE_PATH\"," \
            "\"branch\": \"$WORKTREE_BRANCH\"," \
            "\"commit\": \"$WORKTREE_COMMIT\"," \
            "\"has_changes\": true," \
            "\"changes_summary\": \"$CHANGES_SUMMARY\"," \
            "\"junctions\": $JUNCTIONS_JSON," \
            "\"remote_exists\": $REMOTE_BRANCH_EXISTS," \
            "\"remove_remote\": $REMOVE_REMOTE"
        exit 1
    else
        json_output "ready" 0 \
            "\"worktree_path\": \"$WORKTREE_PATH\"," \
            "\"branch\": \"$WORKTREE_BRANCH\"," \
            "\"commit\": \"$WORKTREE_COMMIT\"," \
            "\"has_changes\": $HAS_CHANGES," \
            "\"changes_summary\": \"$CHANGES_SUMMARY\"," \
            "\"junctions\": $JUNCTIONS_JSON," \
            "\"remote_exists\": $REMOTE_BRANCH_EXISTS," \
            "\"remove_remote\": $REMOVE_REMOTE"
        exit 0
    fi
fi

# === Execute Mode ===

# Check for uncommitted changes (error if not forced)
if [[ "$HAS_CHANGES" == "true" && "$FORCE" != "true" ]]; then
    error_output "uncommitted_changes" "Worktree has uncommitted changes ($CHANGES_SUMMARY). Use --force to remove anyway."
fi

# Track what we did
REMOVED_JUNCTIONS=false
REMOVED_WORKTREE=false
REMOVED_BRANCH=false
REMOVED_REMOTE=false

# Step 1: Remove junctions/symlinks
if [[ "$JUNCTIONS_JSON" != "[]" ]]; then
    remove_junctions "$WORKTREE_PATH"
    REMOVED_JUNCTIONS=true
fi

# Step 2: Remove worktree
FORCE_FLAG=""
if [[ "$FORCE" == "true" ]]; then
    FORCE_FLAG="--force"
fi

if ! git worktree remove $FORCE_FLAG "$WORKTREE_PATH" 2>&1; then
    error_output "worktree_remove_failed" "Failed to remove worktree at $WORKTREE_PATH"
fi
REMOVED_WORKTREE=true

# Step 3: Delete local branch (if not checked out elsewhere)
if [[ -n "$WORKTREE_BRANCH" ]]; then
    # Check if branch is checked out in another worktree
    BRANCH_IN_USE=$(git worktree list --porcelain | grep -A2 "^worktree " | grep "branch refs/heads/$WORKTREE_BRANCH" || true)

    if [[ -z "$BRANCH_IN_USE" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            git branch -D "$WORKTREE_BRANCH" 2>/dev/null || true
        else
            git branch -d "$WORKTREE_BRANCH" 2>/dev/null || true
        fi
        REMOVED_BRANCH=true
    fi
fi

# Step 4: Delete remote branch (if requested)
if [[ "$REMOVE_REMOTE" == "true" && "$REMOTE_BRANCH_EXISTS" == "true" && -n "$WORKTREE_BRANCH" ]]; then
    if git push origin --delete "$WORKTREE_BRANCH" 2>&1; then
        REMOVED_REMOTE=true
    fi
fi

# Output success
json_output "success" 0 \
    "\"worktree_path\": \"$WORKTREE_PATH\"," \
    "\"branch\": \"$WORKTREE_BRANCH\"," \
    "\"removed_junctions\": $REMOVED_JUNCTIONS," \
    "\"removed_worktree\": $REMOVED_WORKTREE," \
    "\"removed_branch\": $REMOVED_BRANCH," \
    "\"removed_remote\": $REMOVED_REMOTE"
