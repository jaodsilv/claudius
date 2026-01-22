#!/bin/bash
# Validate gitignore patterns for existence, tracked file conflicts, and normalization
# Usage: validate-patterns.sh "<repo_root>" "<pattern1>" "<pattern2>" ...

set -uo pipefail

# Convert Windows paths to bash format
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

# Arguments
REPO_ROOT="${1:-}"
shift || true

if [[ -z "$REPO_ROOT" ]]; then
  echo '{"error": "Repository root path required"}' >&2
  exit 1
fi

REPO_ROOT=$(convert_path "$REPO_ROOT")

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo '{"error": "Not a git repository: '"$REPO_ROOT"'"}' >&2
  exit 1
fi

GITIGNORE_FILE="$REPO_ROOT/.gitignore"
PATTERNS=("$@")

if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  echo '{"error": "At least one pattern required"}' >&2
  exit 1
fi

# Read existing patterns from .gitignore
EXISTING_PATTERNS=""
if [[ -f "$GITIGNORE_FILE" ]]; then
  EXISTING_PATTERNS=$(cat "$GITIGNORE_FILE" | tr -d '\r')
fi

# Start JSON array
echo "["

FIRST=true
for pattern in "${PATTERNS[@]}"; do
  [[ -z "$pattern" ]] && continue

  # Normalize pattern: strip leading ./
  normalized="${pattern#./}"

  # Check if it's a directory and add trailing /
  if [[ -d "$REPO_ROOT/$normalized" ]] && [[ ! "$normalized" =~ /$ ]]; then
    normalized="$normalized/"
  fi

  # Check if pattern exists in .gitignore
  exists="false"
  if [[ -n "$EXISTING_PATTERNS" ]]; then
    # Check exact match (with or without trailing /)
    if echo "$EXISTING_PATTERNS" | grep -qxF "$normalized" || \
       echo "$EXISTING_PATTERNS" | grep -qxF "${normalized%/}"; then
      exists="true"
    fi
  fi

  # Check for tracked files matching the pattern
  tracked_matches=""
  cd "$REPO_ROOT" || exit 1
  matches=$(git ls-files -- "$normalized" "${normalized%/}" 2>/dev/null | head -10 | tr -d '\r')
  if [[ -n "$matches" ]]; then
    # Format as JSON array
    tracked_matches=$(echo "$matches" | jq -R -s 'split("\n") | map(select(length > 0))')
  else
    tracked_matches="[]"
  fi

  # Determine status
  if [[ "$exists" == "true" ]]; then
    status="exists"
  elif [[ "$tracked_matches" != "[]" ]]; then
    status="tracked_conflict"
  else
    status="ok"
  fi

  # Output JSON object
  if [[ "$FIRST" == "true" ]]; then
    FIRST=false
  else
    echo ","
  fi

  # Escape pattern for JSON
  escaped_pattern=$(echo "$pattern" | jq -Rs '.')
  escaped_normalized=$(echo "$normalized" | jq -Rs '.')

  cat <<EOF
  {
    "pattern": ${escaped_pattern%$'\n'},
    "exists": $exists,
    "normalized": ${escaped_normalized%$'\n'},
    "trackedMatches": $tracked_matches,
    "status": "$status"
  }
EOF
done

echo "]"
exit 0
