#!/bin/bash
# CI-only version bump script for plugin-aware releases
# Usage: ci-bump-versions.sh [repo-root]
# Outputs JSON summary to stdout; diagnostics to stderr
#
# Detection: For each plugin in marketplace.json, finds the last commit that
# changed its plugin.json, then diffs the plugin folder from that commit to HEAD.
# If any files changed, the plugin gets a version bump.

set -euo pipefail

REPO_ROOT="${1:-.}"

MARKETPLACE_FILE="$REPO_ROOT/.claude-plugin/marketplace.json"
PACKAGE_JSON="$REPO_ROOT/package.json"

# ============================================================================
# Version manipulation (extracted from cc/hooks/scripts/handlers/bump-version.sh)
# ============================================================================

bump_version() {
  local current="$1"
  local increment="${2:-0.0.1}"

  current="${current%%-*}"

  IFS='.' read -r c_major c_minor c_patch <<< "$current"
  c_major="${c_major:-0}"; c_minor="${c_minor:-0}"; c_patch="${c_patch:-0}"

  IFS='.' read -r i_major i_minor i_patch <<< "$increment"
  i_major="${i_major:-0}"; i_minor="${i_minor:-0}"; i_patch="${i_patch:-0}"

  if (( i_major > 0 )); then
    echo "$((c_major + i_major)).0.0"
  elif (( i_minor > 0 )); then
    echo "${c_major}.$((c_minor + i_minor)).0"
  else
    echo "${c_major}.${c_minor}.$((c_patch + i_patch))"
  fi
}

update_json_version() {
  local file="$1"
  local new_version="$2"
  local tmp_file="${file}.tmp"

  if ! jq --arg v "$new_version" '.version = $v' "$file" > "$tmp_file" 2>/dev/null; then
    echo "ERROR: jq failed for $file" >&2
    rm -f "$tmp_file"
    return 1
  fi
  mv "$tmp_file" "$file"
}

update_marketplace_plugin_version() {
  local file="$1"
  local plugin_name="$2"
  local new_version="$3"
  local tmp_file="${file}.tmp"

  if ! jq --arg name "$plugin_name" --arg v "$new_version" \
    '(.plugins[] | select(.name == $name)).version = $v' "$file" > "$tmp_file" 2>/dev/null; then
    echo "ERROR: jq failed for plugin $plugin_name" >&2
    rm -f "$tmp_file"
    return 1
  fi
  mv "$tmp_file" "$file"
}

# ============================================================================
# Validation
# ============================================================================

if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  echo '{"bumped": false, "error": "marketplace.json not found"}'
  exit 0
fi

# ============================================================================
# Detect and bump changed plugins
# ============================================================================

echo "Detecting changed plugins via plugin.json commit history..." >&2

PLUGINS_JSON="[]"
SUMMARY_LINES=""
BUMP_COUNT=0

while IFS='|' read -r name source; do
  [[ -z "$name" ]] && continue

  PLUGIN_JSON="$REPO_ROOT/${source#./}/.claude-plugin/plugin.json"

  if [[ ! -f "$PLUGIN_JSON" ]]; then
    echo "WARNING: plugin.json not found for $name at $PLUGIN_JSON" >&2
    continue
  fi

  LAST_BUMP=$(git -C "$REPO_ROOT" log -1 --format=%H -- "${source#./}/.claude-plugin/plugin.json")

  CHANGED=false
  if [[ -z "$LAST_BUMP" ]]; then
    echo "  $name: new plugin (no prior plugin.json commit)" >&2
    CHANGED=true
  else
    DIFF=$(git -C "$REPO_ROOT" diff --name-only "$LAST_BUMP"...HEAD -- "${source#./}/")
    if [[ -n "$DIFF" ]]; then
      CHANGED=true
    fi
  fi

  if [[ "$CHANGED" == "true" ]]; then
    OLD_VERSION=$(jq -r '.version // "0.0.0"' "$PLUGIN_JSON")
    NEW_VERSION=$(bump_version "$OLD_VERSION" "0.0.1")

    echo "  $name: $OLD_VERSION -> $NEW_VERSION" >&2

    update_json_version "$PLUGIN_JSON" "$NEW_VERSION"
    update_marketplace_plugin_version "$MARKETPLACE_FILE" "$name" "$NEW_VERSION"

    PLUGINS_JSON=$(echo "$PLUGINS_JSON" | jq --arg n "$name" --arg f "$OLD_VERSION" --arg t "$NEW_VERSION" \
      '. + [{"name": $n, "from": $f, "to": $t}]')
    SUMMARY_LINES="${SUMMARY_LINES}\n- **${name}**: ${OLD_VERSION} → ${NEW_VERSION}"
    BUMP_COUNT=$((BUMP_COUNT + 1))
  else
    echo "  $name: no changes" >&2
  fi
done < <(jq -r '.plugins[] | "\(.name)|\(.source)"' "$MARKETPLACE_FILE" | tr -d '\r')

if [[ "$BUMP_COUNT" -eq 0 ]]; then
  echo '{"bumped": false}'
  exit 0
fi

echo "Bumped $BUMP_COUNT plugin(s)." >&2

# ============================================================================
# Bump marketplace root version and package.json
# ============================================================================

OLD_MKT_VERSION=$(jq -r '.version // "0.0.0"' "$MARKETPLACE_FILE")
NEW_MKT_VERSION=$(bump_version "$OLD_MKT_VERSION" "0.0.1")

echo "Marketplace: $OLD_MKT_VERSION -> $NEW_MKT_VERSION" >&2

update_json_version "$MARKETPLACE_FILE" "$NEW_MKT_VERSION"

if [[ -f "$PACKAGE_JSON" ]]; then
  update_json_version "$PACKAGE_JSON" "$NEW_MKT_VERSION"
fi

# ============================================================================
# Output JSON summary
# ============================================================================

SUMMARY="## v${NEW_MKT_VERSION}\n\nPlugins bumped:${SUMMARY_LINES}"

jq -n \
  --argjson bumped true \
  --arg version "$NEW_MKT_VERSION" \
  --arg previousVersion "$OLD_MKT_VERSION" \
  --argjson plugins "$PLUGINS_JSON" \
  --arg summary "$(echo -e "$SUMMARY")" \
  '{bumped: $bumped, version: $version, previousVersion: $previousVersion, plugins: $plugins, summary: $summary}'
