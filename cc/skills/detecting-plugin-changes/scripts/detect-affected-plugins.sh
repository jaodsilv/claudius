#!/bin/bash
# Detect affected plugins from PR or git diff
# Reads marketplace.json and matches changed files to plugin directories

set -uo pipefail

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# Arguments
PR_NUMBER="${1:-}"
WORKDIR="${2:-.}"
WORKDIR=$(convert_path "$WORKDIR")

# Resolve to absolute path if relative
if [[ "$WORKDIR" == "." ]] || [[ -z "$WORKDIR" ]]; then
  WORKDIR=$(convert_path "$(pwd)")
elif [[ ! "$WORKDIR" = /* ]]; then
  WORKDIR=$(convert_path "$(cd "$WORKDIR" && pwd)")
fi

MARKETPLACE_FILE="$WORKDIR/.claude-plugin/marketplace.json"

# Check if marketplace.json exists
if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  echo "error: Marketplace file not found: $MARKETPLACE_FILE" >&2
  exit 1
fi

# Get changed files based on detection method
DETECTION_METHOD=""
CHANGED_FILES=""

if [[ -n "$PR_NUMBER" ]]; then
  # PR mode: get files from PR
  DETECTION_METHOD="pr"
  CHANGED_FILES=$(gh pr view "$PR_NUMBER" --json files --jq '.files[].path' 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "error: Failed to get PR files: $CHANGED_FILES" >&2
    exit 1
  fi
else
  # Git diff mode: get files from uncommitted/unpushed changes
  DETECTION_METHOD="git-diff"

  # First try to find the default branch
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -z "$DEFAULT_BRANCH" ]]; then
    # Fallback: try main, then master
    if git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
      DEFAULT_BRANCH="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
      DEFAULT_BRANCH="master"
    else
      echo "error: Could not determine default branch" >&2
      exit 1
    fi
  fi

  # Get changed files compared to default branch
  CHANGED_FILES=$(git diff --name-only "origin/$DEFAULT_BRANCH"...HEAD 2>&1)
  if [[ $? -ne 0 ]]; then
    # Try without origin prefix
    CHANGED_FILES=$(git diff --name-only "$DEFAULT_BRANCH"...HEAD 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "error: Failed to get git diff: $CHANGED_FILES" >&2
      exit 1
    fi
  fi
fi

# Create temp files for intermediate processing
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "$CHANGED_FILES" > "$TEMP_DIR/changed_files.txt"

# Read plugins from marketplace.json into temp file (remove carriage returns for Windows compatibility)
jq -r '.plugins[] | "\(.source | ltrimstr("./"))|\(.name)"' "$MARKETPLACE_FILE" | tr -d '\r' > "$TEMP_DIR/plugins_map.txt"

# Process files and build result
# First, build a mapping of plugin names to their files
cat "$TEMP_DIR/changed_files.txt" | tr -d '\r' | while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Check against each plugin
  MATCHED=""
  while IFS='|' read -r source name; do
    [[ -z "$source" ]] && continue

    if [[ "$file" == "$source"/* ]] || [[ "$file" == "$source" ]]; then
      REL_PATH="${file#$source/}"
      echo "$name|$source|$REL_PATH"
      MATCHED="yes"
      break
    fi
  done < "$TEMP_DIR/plugins_map.txt"

  if [[ -z "$MATCHED" ]]; then
    echo "UNMATCHED||$file"
  fi
done > "$TEMP_DIR/matches.txt"

# Build the final JSON using jq
{
  # Changed files array (remove carriage returns for Windows compatibility)
  CHANGED_JSON=$(cat "$TEMP_DIR/changed_files.txt" | tr -d '\r' | jq -R -s 'split("\n") | map(select(length > 0))')

  # Build affected plugins using awk and jq
  PLUGINS_JSON=$(awk -F'|' '
    $1 != "UNMATCHED" && $1 != "" {
      plugins[$1]["source"] = $2
      plugins[$1]["files"][length(plugins[$1]["files"])] = $3
    }
    END {
      first = 1
      printf "["
      for (name in plugins) {
        if (!first) printf ","
        first = 0
        printf "{\"name\":\"%s\",\"source\":\"./%s\",\"files\":[", name, plugins[name]["source"]
        ffirst = 1
        for (i in plugins[name]["files"]) {
          if (!ffirst) printf ","
          ffirst = 0
          gsub(/"/, "\\\"", plugins[name]["files"][i])
          printf "\"%s\"", plugins[name]["files"][i]
        }
        printf "]}"
      }
      printf "]"
    }
  ' "$TEMP_DIR/matches.txt")

  # Build unmatched files
  UNMATCHED_LINES=$(grep '^UNMATCHED||' "$TEMP_DIR/matches.txt" 2>/dev/null | cut -d'|' -f3 || true)
  if [[ -n "$UNMATCHED_LINES" ]]; then
    UNMATCHED_JSON=$(echo "$UNMATCHED_LINES" | jq -R -s 'split("\n") | map(select(length > 0))')
  else
    UNMATCHED_JSON='[]'
  fi

  # Count total
  TOTAL=$(echo "$CHANGED_JSON" | jq 'length')

  # PR number (must be valid JSON: number or null)
  if [[ -n "$PR_NUMBER" ]]; then
    PR_JSON="$PR_NUMBER"
  else
    PR_JSON=null
  fi

  # Combine everything
  jq -n \
    --arg method "$DETECTION_METHOD" \
    --argjson pr "$PR_JSON" \
    --argjson files "$CHANGED_JSON" \
    --argjson plugins "$PLUGINS_JSON" \
    --argjson total "$TOTAL" \
    --argjson unmatched "$UNMATCHED_JSON" \
    '{
      detectionMethod: $method,
      prNumber: $pr,
      changedFiles: $files,
      affectedPlugins: $plugins,
      totalChangedFiles: $total,
      unmatchedFiles: $unmatched
    }'
}

exit 0
