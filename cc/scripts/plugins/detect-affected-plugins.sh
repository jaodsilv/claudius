#!/bin/bash
# Detect affected plugins from PR or git diff
# Reads marketplace.json and matches changed files to plugin directories

# Parse --plugin-root flag
for _arg in "$@"; do
  if [[ "$_arg" == --plugin-root=* ]]; then
    _PLUGIN_ROOT_PARAM="${_arg#--plugin-root=}"
    break
  fi
done

# Priority: env var > --plugin-root flag > self-location fallback
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${_PLUGIN_ROOT_PARAM:-$(cd "$(dirname "$0")/../.." && pwd)}}"

set -euo pipefail

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# Arguments
PR_NUMBER="${1:-}"
WORKDIR="${2:-.}"
BASE_COMMIT="${3:-}"  # Optional: compare against this commit instead of default branch
WORKDIR=$(convert_path "$WORKDIR")

# Resolve to absolute path if relative
if [[ "$WORKDIR" == "." ]] || [[ -z "$WORKDIR" ]]; then
  WORKDIR=$(convert_path "$(pwd)")
elif [[ ! "$WORKDIR" = /* ]]; then
  WORKDIR=$(convert_path "$(cd "$WORKDIR" && pwd)")
fi

MARKETPLACE_FILE="$WORKDIR/.claude-plugin/marketplace.json"
METADATA_FILE="$WORKDIR/.thoughts/marketplace/latest-version-bump.yaml"

# Check if marketplace.json exists
if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  echo "error: Marketplace file not found: $MARKETPLACE_FILE" >&2
  exit 1
fi

# Check if a file is newer than a given ISO8601 datetime
# Returns 0 if newer, 1 if older or file doesn't exist
file_is_newer_than() {
  local file="$1"
  local reference_datetime="$2"

  # If no reference datetime, assume newer (first-time bump)
  if [[ -z "$reference_datetime" ]] || [[ "$reference_datetime" == "unknown" ]] || [[ "$reference_datetime" == "null" ]]; then
    return 0
  fi

  # Skip non-existent files (moved/renamed/deleted files)
  # These are already part of commit history, not new changes
  if [[ ! -f "$file" ]]; then
    return 1  # Not newer - file doesn't exist
  fi

  local file_mtime
  file_mtime=$(date -Iseconds -r "$file" 2>/dev/null)
  if [[ -z "$file_mtime" ]]; then
    return 1  # Cannot determine mtime, skip this file
  fi

  # ISO8601 strings can be compared lexicographically
  [[ "$file_mtime" > "$reference_datetime" ]]
}

# Get changed files based on detection method
DETECTION_METHOD=""
CHANGED_FILES=""

if [[ -n "$PR_NUMBER" ]]; then
  # PR mode: get files from PR
  DETECTION_METHOD="pr"
  CHANGED_FILES=$(gh pr view "$PR_NUMBER" --json files --jq '.files[].path')
  if [[ $? -ne 0 ]]; then
    echo "error: Failed to get PR files" >&2
    exit 1
  fi
else
  # Git diff mode: get files from uncommitted/unpushed changes

  if [[ -n "$BASE_COMMIT" ]]; then
    # Use provided base commit (from last version bump)
    DETECTION_METHOD="git-diff-from-commit"
    CHANGED_FILES=$(git diff --name-only "$BASE_COMMIT"...HEAD 2>&1)
    if [[ $? -ne 0 ]]; then
      # Fallback to default branch if commit not found
      echo "warning: Base commit $BASE_COMMIT not found, falling back to default branch" >&2
      BASE_COMMIT=""
    fi
  fi

  # If no BASE_COMMIT provided or fallback needed
  if [[ -z "$BASE_COMMIT" ]]; then
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

  # Add uncommitted changes (both staged and unstaged)
  # This ensures changes are detected even when BASE_COMMIT == HEAD
  UNCOMMITTED_FILES=$(git -C "$WORKDIR" diff --name-only HEAD 2>/dev/null)
  STAGED_FILES=$(git -C "$WORKDIR" diff --name-only --cached 2>/dev/null)

  if [[ -n "$UNCOMMITTED_FILES" ]]; then
    CHANGED_FILES="${CHANGED_FILES}"$'\n'"${UNCOMMITTED_FILES}"
  fi
  if [[ -n "$STAGED_FILES" ]]; then
    CHANGED_FILES="${CHANGED_FILES}"$'\n'"${STAGED_FILES}"
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
while IFS= read -r file; do
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
done < <(cat "$TEMP_DIR/changed_files.txt" | tr -d '\r') > "$TEMP_DIR/matches.txt"

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

  # Filter plugins by datetime if metadata file exists
  if [[ -f "$METADATA_FILE" ]]; then
    FILTERED_PLUGINS="[]"

    # Process each plugin in PLUGINS_JSON (tr -d '\r' for Windows CRLF)
    for plugin_name in $(echo "$PLUGINS_JSON" | jq -r '.[].name' | tr -d '\r'); do
      # Get plugin's last bump datetime from metadata
      last_bump=$(yq -r ".plugins.$plugin_name.datetime // \"\"" "$METADATA_FILE" 2>/dev/null)

      # Get plugin source from PLUGINS_JSON (tr -d '\r' for Windows CRLF)
      plugin_source=$(echo "$PLUGINS_JSON" | jq -r --arg n "$plugin_name" '.[] | select(.name == $n) | .source' | tr -d '\r' | sed 's|^\./||')

      has_newer_file=false

      # Check each file in this plugin
      while IFS= read -r rel_file; do
        [[ -z "$rel_file" ]] && continue
        abs_file="$WORKDIR/$plugin_source/$rel_file"

        if file_is_newer_than "$abs_file" "$last_bump"; then
          has_newer_file=true
          break
        fi
      done < <(echo "$PLUGINS_JSON" | jq -r --arg n "$plugin_name" '.[] | select(.name == $n) | .files[]' | tr -d '\r')

      if [[ "$has_newer_file" == "true" ]]; then
        # Add this plugin to filtered list
        plugin_entry=$(echo "$PLUGINS_JSON" | jq --arg n "$plugin_name" '.[] | select(.name == $n)')
        FILTERED_PLUGINS=$(echo "$FILTERED_PLUGINS" | jq --argjson p "$plugin_entry" '. + [$p]')
      fi
    done

    PLUGINS_JSON="$FILTERED_PLUGINS"
  fi

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

  # Write large JSON to temp files to avoid argument list too long errors
  echo "$CHANGED_JSON" > "$TEMP_DIR/changed.json"
  echo "$PLUGINS_JSON" > "$TEMP_DIR/plugins.json"
  echo "$UNMATCHED_JSON" > "$TEMP_DIR/unmatched.json"

  # Combine everything using slurpfile for large data
  jq -n \
    --arg method "$DETECTION_METHOD" \
    --argjson pr "$PR_JSON" \
    --slurpfile files "$TEMP_DIR/changed.json" \
    --slurpfile plugins "$TEMP_DIR/plugins.json" \
    --argjson total "$TOTAL" \
    --slurpfile unmatched "$TEMP_DIR/unmatched.json" \
    '{
      detectionMethod: $method,
      prNumber: $pr,
      changedFiles: $files[0],
      affectedPlugins: $plugins[0],
      totalChangedFiles: $total,
      unmatchedFiles: $unmatched[0]
    }'
}

exit 0
