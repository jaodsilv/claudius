#!/bin/bash
# Handler for /cc:bump-version command
# Script-only - does ALL the work, no LLM phase needed
# Exit 0: Success - versions bumped
# Exit 2: Block - validation failed or nothing to bump

log_section "Bump-Version Handler"

MARKETPLACE_FILE="$WORKTREE/.claude-plugin/marketplace.json"
METADATA_FILE="$WORKTREE/.thoughts/marketplace/latest-version-bump.yaml"
PACKAGE_JSON="$WORKTREE/package.json"

# Parse arguments
PLUGINS_ARG=""
NO_MARKETPLACE=false
MARKETPLACE_ONLY=false
BUMP_VERSION="0.0.1"
BUMP_MARKETPLACE_VERSION=""
PR_NUMBER=""

# Parse --plugins, --no-marketplace, --marketplace, --marketplace-only, --bump-version, --bump-marketplace-version, --pr
while [[ -n "$ARGS" ]]; do
  case "$ARGS" in
    --plugins\ *)
      PLUGINS_ARG=$(echo "$ARGS" | sed -n 's|^--plugins[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      ARGS=$(echo "$ARGS" | sed 's|^--plugins[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    --no-marketplace*)
      NO_MARKETPLACE=true
      ARGS=$(echo "$ARGS" | sed 's|^--no-marketplace[[:space:]]*||')
      ;;
    --marketplace-only*)
      MARKETPLACE_ONLY=true
      ARGS=$(echo "$ARGS" | sed 's|^--marketplace-only[[:space:]]*||')
      ;;
    --marketplace*)
      # Default behavior, just consume the flag
      ARGS=$(echo "$ARGS" | sed 's|^--marketplace[[:space:]]*||')
      ;;
    --bump-version\ *)
      BUMP_VERSION=$(echo "$ARGS" | sed -n 's|^--bump-version[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      # Remove leading dash if present (supports -x.y.z format)
      BUMP_VERSION="${BUMP_VERSION#-}"
      ARGS=$(echo "$ARGS" | sed 's|^--bump-version[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    --bump-marketplace-version\ *)
      BUMP_MARKETPLACE_VERSION=$(echo "$ARGS" | sed -n 's|^--bump-marketplace-version[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      BUMP_MARKETPLACE_VERSION="${BUMP_MARKETPLACE_VERSION#-}"
      ARGS=$(echo "$ARGS" | sed 's|^--bump-marketplace-version[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    --pr\ *)
      PR_NUMBER=$(echo "$ARGS" | sed -n 's|^--pr[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      ARGS=$(echo "$ARGS" | sed 's|^--pr[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    *)
      # Skip unknown args
      ARGS=$(echo "$ARGS" | sed 's|^[^[:space:]]*[[:space:]]*||')
      ;;
  esac
done

log_debug "PLUGINS_ARG" "$PLUGINS_ARG"
log_debug "NO_MARKETPLACE" "$NO_MARKETPLACE"
log_debug "MARKETPLACE_ONLY" "$MARKETPLACE_ONLY"
log_debug "BUMP_VERSION" "$BUMP_VERSION"
log_debug "BUMP_MARKETPLACE_VERSION" "$BUMP_MARKETPLACE_VERSION"
log_debug "PR_NUMBER" "$PR_NUMBER"

# If --bump-marketplace-version not set, use --bump-version
if [[ -z "$BUMP_MARKETPLACE_VERSION" ]]; then
  BUMP_MARKETPLACE_VERSION="$BUMP_VERSION"
fi

# Check marketplace.json exists
if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  log_error "No marketplace.json found"
  log_exit 2 "no marketplace.json"
  echo "Error: marketplace.json not found at $MARKETPLACE_FILE" >&2
  exit 2
fi

# ============================================================================
# Version manipulation functions
# ============================================================================

# Calculate new version by adding increment to current
# bump_version "1.2.3" "0.0.1" -> "1.2.4"
# bump_version "1.2.3" "0.1.0" -> "1.3.0"
# bump_version "1.2.3" "1.0.0" -> "2.0.0"
bump_version() {
  local current="$1"
  local increment="$2"

  # Strip any prerelease suffix
  current="${current%%-*}"

  # Parse current version
  IFS='.' read -r c_major c_minor c_patch <<< "$current"
  c_major="${c_major:-0}"
  c_minor="${c_minor:-0}"
  c_patch="${c_patch:-0}"

  # Parse increment
  IFS='.' read -r i_major i_minor i_patch <<< "$increment"
  i_major="${i_major:-0}"
  i_minor="${i_minor:-0}"
  i_patch="${i_patch:-0}"

  # Calculate new version based on which position has non-zero increment
  if (( i_major > 0 )); then
    # Major bump: X+i.0.0
    echo "$((c_major + i_major)).0.0"
  elif (( i_minor > 0 )); then
    # Minor bump: X.Y+i.0
    echo "${c_major}.$((c_minor + i_minor)).0"
  else
    # Patch bump: X.Y.Z+i
    echo "${c_major}.${c_minor}.$((c_patch + i_patch))"
  fi
}

# Update version in a JSON file using jq
# Returns 0 on success, 1 on failure
update_json_version() {
  local file="$1"
  local new_version="$2"
  local tmp_file="${file}.tmp"

  if ! jq --arg v "$new_version" '.version = $v' "$file" > "$tmp_file" 2>/dev/null; then
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$file"
  return 0
}

# Update plugin version in marketplace.json
# Returns 0 on success, 1 on failure
update_marketplace_plugin_version() {
  local file="$1"
  local plugin_name="$2"
  local new_version="$3"
  local tmp_file="${file}.tmp"

  if ! jq --arg name "$plugin_name" --arg v "$new_version" \
    '(.plugins[] | select(.name == $name)).version = $v' "$file" > "$tmp_file" 2>/dev/null; then
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$file"
  return 0
}

# ============================================================================
# Auto-detection logic
# ============================================================================

DETECTED_PLUGINS=""
DETECTION_METHOD=""

if [[ -z "$PLUGINS_ARG" ]] && [[ "$MARKETPLACE_ONLY" != "true" ]]; then
  log_section "Auto-Detection"

  # Check for metadata file
  if [[ -f "$METADATA_FILE" ]]; then
    log_info "Found metadata file, checking for changes since last bump"

    LAST_COMMIT=$(yq -r '.commit // ""' "$METADATA_FILE" 2>/dev/null || echo "")
    log_debug "LAST_COMMIT" "$LAST_COMMIT"

    if [[ -n "$LAST_COMMIT" ]]; then
      # Check if HEAD is the same as last bump commit
      HEAD_COMMIT=$(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null || echo "")
      log_debug "HEAD_COMMIT" "$HEAD_COMMIT"

      if [[ "$HEAD_COMMIT" == "$LAST_COMMIT"* ]] || [[ "$LAST_COMMIT" == "$HEAD_COMMIT"* ]]; then
        # Check for uncommitted changes
        UNCOMMITTED=$(git -C "$WORKTREE" status --porcelain 2>/dev/null | grep -v '^\?\?' | head -1 || true)
        if [[ -z "$UNCOMMITTED" ]]; then
          log_warn "Last bump commit is HEAD and no uncommitted changes"
          log_exit 2 "nothing to bump"
          echo "Nothing to bump: Last version bump was at current HEAD and no uncommitted changes." >&2
          echo "Make changes before running bump-version again." >&2
          exit 2
        fi
        log_info "Found uncommitted changes since last bump"
      fi
    fi
  fi

  # Use detect-affected-plugins.sh script
  DETECT_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/detecting-plugin-changes/scripts/detect-affected-plugins.sh"

  if [[ -f "$DETECT_SCRIPT" ]]; then
    log_info "Running detect-affected-plugins.sh"
    DETECTION_RESULT=$(bash "$DETECT_SCRIPT" "$PR_NUMBER" "$WORKTREE" 2>&1)
    DETECT_EXIT=$?
    log_json "DETECTION_RESULT" "$DETECTION_RESULT"
    log_debug "DETECT_EXIT" "$DETECT_EXIT"

    if [[ $DETECT_EXIT -ne 0 ]]; then
      log_error "Detection script failed"
      log_exit 2 "detection failed"
      echo "Error detecting affected plugins: $DETECTION_RESULT" >&2
      exit 2
    fi

    DETECTION_METHOD=$(echo "$DETECTION_RESULT" | jq -r '.detectionMethod // ""')
    DETECTED_PLUGINS=$(echo "$DETECTION_RESULT" | jq -r '.affectedPlugins[].name' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    TOTAL_FILES=$(echo "$DETECTION_RESULT" | jq -r '.totalChangedFiles // 0')

    log_debug "DETECTION_METHOD" "$DETECTION_METHOD"
    log_debug "DETECTED_PLUGINS" "$DETECTED_PLUGINS"
    log_debug "TOTAL_FILES" "$TOTAL_FILES"
  else
    log_error "Detection script not found: $DETECT_SCRIPT"
    log_exit 2 "detection script missing"
    echo "Error: detect-affected-plugins.sh not found" >&2
    exit 2
  fi
else
  DETECTED_PLUGINS="$PLUGINS_ARG"
  DETECTION_METHOD="explicit"
fi

# Validate we have something to bump
if [[ -z "$DETECTED_PLUGINS" ]] && [[ "$MARKETPLACE_ONLY" != "true" ]]; then
  log_warn "No plugins detected"
  log_exit 2 "no plugins"
  echo "No plugins detected to bump." >&2
  echo "Use --plugins <list> to specify plugins explicitly, or --marketplace-only to bump only marketplace version." >&2
  exit 2
fi

# ============================================================================
# Plugin validation and version collection
# ============================================================================

declare -A PLUGIN_SOURCES
declare -A PLUGIN_CURRENT_VERSIONS
declare -A PLUGIN_NEW_VERSIONS

if [[ -n "$DETECTED_PLUGINS" ]]; then
  log_section "Plugin Validation"
  IFS=',' read -ra PLUGIN_ARRAY <<< "$DETECTED_PLUGINS"
  VALID_PLUGINS=""

  for plugin in "${PLUGIN_ARRAY[@]}"; do
    plugin=$(echo "$plugin" | xargs)  # trim whitespace
    [[ -z "$plugin" ]] && continue

    # Check if plugin exists in marketplace.json
    PLUGIN_SOURCE=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .source' "$MARKETPLACE_FILE" 2>/dev/null)
    log_debug "PLUGIN_SOURCE for $plugin" "$PLUGIN_SOURCE"

    if [[ -z "$PLUGIN_SOURCE" ]]; then
      log_warn "Plugin '$plugin' not found in marketplace.json"
      echo "Warning: Plugin '$plugin' not found in marketplace.json, skipping" >&2
      continue
    fi

    # Check if plugin.json exists
    PLUGIN_JSON="$WORKTREE/${PLUGIN_SOURCE#./}/.claude-plugin/plugin.json"
    if [[ ! -f "$PLUGIN_JSON" ]]; then
      log_warn "Plugin '$plugin' plugin.json not found at $PLUGIN_JSON"
      echo "Warning: Plugin '$plugin' plugin.json not found, skipping" >&2
      continue
    fi

    # Read current version from plugin.json
    CURRENT_VERSION=$(jq -r '.version // "0.0.0"' "$PLUGIN_JSON" 2>/dev/null)
    NEW_VERSION=$(bump_version "$CURRENT_VERSION" "$BUMP_VERSION")

    PLUGIN_SOURCES["$plugin"]="$PLUGIN_SOURCE"
    PLUGIN_CURRENT_VERSIONS["$plugin"]="$CURRENT_VERSION"
    PLUGIN_NEW_VERSIONS["$plugin"]="$NEW_VERSION"

    log_debug "Plugin $plugin: $CURRENT_VERSION -> $NEW_VERSION" ""

    if [[ -z "$VALID_PLUGINS" ]]; then
      VALID_PLUGINS="$plugin"
    else
      VALID_PLUGINS="$VALID_PLUGINS,$plugin"
    fi
  done

  if [[ -z "$VALID_PLUGINS" ]] && [[ "$MARKETPLACE_ONLY" != "true" ]]; then
    log_error "No valid plugins found"
    log_exit 2 "no valid plugins"
    echo "Error: No valid plugins found to bump" >&2
    exit 2
  fi

  DETECTED_PLUGINS="$VALID_PLUGINS"
fi

# ============================================================================
# Get marketplace/package.json versions
# ============================================================================

log_section "Version Calculation"

MARKETPLACE_CURRENT_VERSION=$(jq -r '.version // "0.0.0"' "$MARKETPLACE_FILE" 2>/dev/null)
MARKETPLACE_NEW_VERSION=$(bump_version "$MARKETPLACE_CURRENT_VERSION" "$BUMP_MARKETPLACE_VERSION")

log_debug "Marketplace: $MARKETPLACE_CURRENT_VERSION -> $MARKETPLACE_NEW_VERSION" ""

PACKAGE_CURRENT_VERSION=""
PACKAGE_NEW_VERSION=""
if [[ -f "$PACKAGE_JSON" ]]; then
  PACKAGE_CURRENT_VERSION=$(jq -r '.version // ""' "$PACKAGE_JSON" 2>/dev/null)
  if [[ -n "$PACKAGE_CURRENT_VERSION" ]]; then
    PACKAGE_NEW_VERSION=$(bump_version "$PACKAGE_CURRENT_VERSION" "$BUMP_MARKETPLACE_VERSION")
    log_debug "Package.json: $PACKAGE_CURRENT_VERSION -> $PACKAGE_NEW_VERSION" ""
  fi
fi

# ============================================================================
# Apply version updates
# ============================================================================

log_section "Applying Updates"

MODIFIED_FILES=()
ERRORS=()

# 1. Update individual plugin.json files
if [[ "$MARKETPLACE_ONLY" != "true" ]] && [[ -n "$DETECTED_PLUGINS" ]]; then
  IFS=',' read -ra PLUGIN_ARRAY <<< "$DETECTED_PLUGINS"
  for plugin in "${PLUGIN_ARRAY[@]}"; do
    plugin=$(echo "$plugin" | xargs)
    [[ -z "$plugin" ]] && continue

    PLUGIN_SOURCE="${PLUGIN_SOURCES[$plugin]}"
    PLUGIN_JSON="$WORKTREE/${PLUGIN_SOURCE#./}/.claude-plugin/plugin.json"
    NEW_VERSION="${PLUGIN_NEW_VERSIONS[$plugin]}"

    log_info "Updating $plugin plugin.json to $NEW_VERSION"
    if update_json_version "$PLUGIN_JSON" "$NEW_VERSION"; then
      MODIFIED_FILES+=("$PLUGIN_JSON")
    else
      ERRORS+=("Failed to update $PLUGIN_JSON")
      log_error "Failed to update $PLUGIN_JSON"
    fi
  done
fi

# 2. Update marketplace.json plugin entries
if [[ "$MARKETPLACE_ONLY" != "true" ]] && [[ -n "$DETECTED_PLUGINS" ]]; then
  IFS=',' read -ra PLUGIN_ARRAY <<< "$DETECTED_PLUGINS"
  for plugin in "${PLUGIN_ARRAY[@]}"; do
    plugin=$(echo "$plugin" | xargs)
    [[ -z "$plugin" ]] && continue

    NEW_VERSION="${PLUGIN_NEW_VERSIONS[$plugin]}"

    log_info "Updating marketplace entry for $plugin to $NEW_VERSION"
    if update_marketplace_plugin_version "$MARKETPLACE_FILE" "$plugin" "$NEW_VERSION"; then
      # Don't double-add marketplace file
      if [[ ! " ${MODIFIED_FILES[*]} " =~ " ${MARKETPLACE_FILE} " ]]; then
        MODIFIED_FILES+=("$MARKETPLACE_FILE")
      fi
    else
      ERRORS+=("Failed to update marketplace entry for $plugin")
      log_error "Failed to update marketplace entry for $plugin"
    fi
  done
fi

# 3. Update marketplace.json root version (unless --no-marketplace)
if [[ "$NO_MARKETPLACE" != "true" ]]; then
  log_info "Updating marketplace.json root version to $MARKETPLACE_NEW_VERSION"
  if update_json_version "$MARKETPLACE_FILE" "$MARKETPLACE_NEW_VERSION"; then
    if [[ ! " ${MODIFIED_FILES[*]} " =~ " ${MARKETPLACE_FILE} " ]]; then
      MODIFIED_FILES+=("$MARKETPLACE_FILE")
    fi
  else
    ERRORS+=("Failed to update marketplace.json root version")
    log_error "Failed to update marketplace.json root version"
  fi
fi

# 4. Update package.json root version (if exists, unless --no-marketplace)
if [[ "$NO_MARKETPLACE" != "true" ]] && [[ -n "$PACKAGE_NEW_VERSION" ]]; then
  log_info "Updating package.json to $PACKAGE_NEW_VERSION"
  if update_json_version "$PACKAGE_JSON" "$PACKAGE_NEW_VERSION"; then
    MODIFIED_FILES+=("$PACKAGE_JSON")
  else
    ERRORS+=("Failed to update package.json")
    log_error "Failed to update package.json"
  fi
fi

# ============================================================================
# Update metadata file
# ============================================================================

log_section "Updating Metadata"

# Create directory if needed
mkdir -p "$(dirname "$METADATA_FILE")"

HEAD_COMMIT=$(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -Iseconds)

# Build YAML content
{
  echo "# Last version bump metadata"
  echo "commit: $HEAD_COMMIT"
  echo "datetime: \"$TIMESTAMP\""
  echo "plugins:"

  if [[ -n "$DETECTED_PLUGINS" ]]; then
    IFS=',' read -ra PLUGIN_ARRAY <<< "$DETECTED_PLUGINS"
    for plugin in "${PLUGIN_ARRAY[@]}"; do
      plugin=$(echo "$plugin" | xargs)
      [[ -z "$plugin" ]] && continue
      echo "  $plugin:"
      echo "    datetime: \"$TIMESTAMP\""
      echo "    commit: $HEAD_COMMIT"
      echo "    version: ${PLUGIN_NEW_VERSIONS[$plugin]}"
    done
  fi

  if [[ "$NO_MARKETPLACE" != "true" ]]; then
    echo "marketplace:"
    echo "  datetime: \"$TIMESTAMP\""
    echo "  commit: $HEAD_COMMIT"
    echo "  version: $MARKETPLACE_NEW_VERSION"
  fi
} > "$METADATA_FILE"

MODIFIED_FILES+=("$METADATA_FILE")
log_info "Metadata updated: $METADATA_FILE"

# ============================================================================
# Output summary
# ============================================================================

log_section "Output"

echo ""
echo "=== Version Bump Complete ==="
echo ""
echo "| File | Before | After |"
echo "|------|--------|-------|"

# Plugin versions
if [[ "$MARKETPLACE_ONLY" != "true" ]] && [[ -n "$DETECTED_PLUGINS" ]]; then
  IFS=',' read -ra PLUGIN_ARRAY <<< "$DETECTED_PLUGINS"
  for plugin in "${PLUGIN_ARRAY[@]}"; do
    plugin=$(echo "$plugin" | xargs)
    [[ -z "$plugin" ]] && continue
    printf "| %s/plugin.json | %s | %s |\n" "$plugin" "${PLUGIN_CURRENT_VERSIONS[$plugin]}" "${PLUGIN_NEW_VERSIONS[$plugin]}"
  done
fi

# Marketplace version
if [[ "$NO_MARKETPLACE" != "true" ]]; then
  printf "| marketplace.json | %s | %s |\n" "$MARKETPLACE_CURRENT_VERSION" "$MARKETPLACE_NEW_VERSION"
fi

# Package.json version
if [[ "$NO_MARKETPLACE" != "true" ]] && [[ -n "$PACKAGE_NEW_VERSION" ]]; then
  printf "| package.json | %s | %s |\n" "$PACKAGE_CURRENT_VERSION" "$PACKAGE_NEW_VERSION"
fi

echo ""
echo "Detection method: $DETECTION_METHOD"
echo "Bump increment: $BUMP_VERSION"
if [[ "$BUMP_MARKETPLACE_VERSION" != "$BUMP_VERSION" ]]; then
  echo "Marketplace bump: $BUMP_MARKETPLACE_VERSION"
fi
echo ""
echo "Files modified:"
for f in "${MODIFIED_FILES[@]}"; do
  echo "  - $f"
done
echo ""
echo "Metadata updated: $METADATA_FILE"
echo ""

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "Errors encountered:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  echo ""
fi

echo "Next: Review changes with 'git diff', then commit and push"
echo ""
echo "=== Done ==="

log_exit 0 "versions bumped successfully"
exit 0
