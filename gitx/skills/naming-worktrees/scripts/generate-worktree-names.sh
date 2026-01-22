#!/bin/bash
# Generates abbreviated worktree directory names from branch names
# Usage: generate-worktree-names.sh <branch_name>
# Output: JSON with suggested names and paths

set -uo pipefail

BRANCH="${1:-}"

if [[ -z "$BRANCH" ]]; then
  echo '{"error": "No branch name provided"}' >&2
  exit 1
fi

# Get repository root (default branch worktree path)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null)
REPO_ROOT=$(git worktree list | grep -E "\[$DEFAULT_BRANCH\]$" | awk '{print $1}')

# Fallback to first worktree if default branch worktree not found
if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT=$(git worktree list | head -1 | awk '{print $1}')
fi

# Get parent directory
PARENT_DIR=$(dirname "$REPO_ROOT")

# Get existing worktree directory names for collision detection
EXISTING_DIRS=$(git worktree list | awk '{print $1}' | xargs -I{} basename {} 2>/dev/null | tr '\n' ' ')

# Reserved names to avoid
RESERVED_NAMES="main master develop HEAD origin tmp temp test build dist node_modules"

# Step 1: Extract description after type prefix
# feature/issue-123-add-auth -> issue-123-add-auth
DESCRIPTION=$(echo "$BRANCH" | sed -E 's|^[^/]+/||')

# Step 2: Remove issue patterns from start
# issue-123-add-auth -> add-auth
CLEANED=$(echo "$DESCRIPTION" | sed -E 's|^issue-[0-9]+-||i; s|^#[0-9]+-||; s|^[0-9]+-||; s|^[A-Z]+-[0-9]+-||')

# If cleaning removed everything, use original description
if [[ -z "$CLEANED" ]]; then
  CLEANED="$DESCRIPTION"
fi

# Step 3: Split by hyphens and generate options
IFS='-' read -ra WORDS <<< "$CLEANED"
OPTIONS=()

# Build options from last word to full phrase
for ((i=${#WORDS[@]}-1; i>=0; i--)); do
  OPTION=""
  for ((j=i; j<${#WORDS[@]}; j++)); do
    if [[ -n "$OPTION" ]]; then
      OPTION="$OPTION-${WORDS[$j]}"
    else
      OPTION="${WORDS[$j]}"
    fi
  done

  # Filter out single char, numeric-only, and meaningless words
  if [[ ${#OPTION} -gt 1 ]] && [[ ! "$OPTION" =~ ^[0-9]+$ ]]; then
    # Skip if it's a standalone meaningless word
    MEANINGLESS="fix add feature bugfix hotfix release chore refactor docs update"
    IS_MEANINGLESS=false
    for word in $MEANINGLESS; do
      if [[ "$OPTION" == "$word" ]]; then
        IS_MEANINGLESS=true
        break
      fi
    done

    if [[ "$IS_MEANINGLESS" == "false" ]]; then
      OPTIONS+=("$OPTION")
    fi
  fi
done

# Handle version strings specially (e.g., v1.2.0)
if [[ "$CLEANED" =~ ^v[0-9]+\.[0-9]+ ]]; then
  OPTIONS=("$CLEANED")
fi

# Limit to 5 options (shortest first, so reverse the array)
FINAL_OPTIONS=()
for ((i=${#OPTIONS[@]}-1; i>=0 && ${#FINAL_OPTIONS[@]}<5; i--)); do
  FINAL_OPTIONS+=("${OPTIONS[$i]}")
done

# If no options generated, use the cleaned description
if [[ ${#FINAL_OPTIONS[@]} -eq 0 ]]; then
  FINAL_OPTIONS=("$CLEANED")
fi

# Step 4: Check collisions and add suffixes if needed
check_collision() {
  local name="$1"
  # Check against existing worktrees
  if echo "$EXISTING_DIRS" | grep -qw "$name"; then
    return 0 # collision
  fi
  # Check against reserved names
  if echo "$RESERVED_NAMES" | grep -qw "$name"; then
    return 0 # collision
  fi
  return 1 # no collision
}

VALID_OPTIONS=()
for opt in "${FINAL_OPTIONS[@]}"; do
  FINAL_NAME="$opt"

  if check_collision "$FINAL_NAME"; then
    # Try adding numeric suffix
    for suffix in 2 3 4 5 6 7 8 9 10; do
      FINAL_NAME="$opt-$suffix"
      if ! check_collision "$FINAL_NAME"; then
        break
      fi
      if [[ $suffix -eq 10 ]]; then
        FINAL_NAME="" # Too many collisions
      fi
    done
  fi

  if [[ -n "$FINAL_NAME" ]]; then
    VALID_OPTIONS+=("$FINAL_NAME")
  fi
done

# Build JSON output
echo "{"
echo "  \"branch\": \"$BRANCH\","
echo "  \"parent_dir\": \"$PARENT_DIR\","
echo "  \"options\": ["

FIRST=true
for opt in "${VALID_OPTIONS[@]}"; do
  if [[ "$FIRST" == "true" ]]; then
    FIRST=false
  else
    echo ","
  fi
  echo -n "    {\"name\": \"$opt\", \"path\": \"$PARENT_DIR/$opt\"}"
done

echo ""
echo "  ]"
echo "}"
