#!/bin/bash
# Handler for /cc:bump-version command
# Script-only - does ALL the work, no LLM phase needed
# Exit 0: Success - versions bumped (JSON blocking output)
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
WORKTREE_ARG=""
SCAN_MODE=false
COMMIT_MODE=""  # "force", "skip", or "" (auto-detect)

# Parse all supported arguments
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
    --delta\ *)
      BUMP_VERSION=$(echo "$ARGS" | sed -n 's|^--delta[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      # Remove leading dash if present (supports -x.y.z format)
      BUMP_VERSION="${BUMP_VERSION#-}"
      ARGS=$(echo "$ARGS" | sed 's|^--delta[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    --bump-version\ *)
      # Deprecated alias for --delta
      BUMP_VERSION=$(echo "$ARGS" | sed -n 's|^--bump-version[[:space:]]\+\([^[:space:]]*\).*|\1|p')
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
    --worktree\ *)
      WORKTREE_ARG=$(echo "$ARGS" | sed -n 's|^--worktree[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      ARGS=$(echo "$ARGS" | sed 's|^--worktree[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    --scan*)
      SCAN_MODE=true
      ARGS=$(echo "$ARGS" | sed 's|^--scan[[:space:]]*||')
      ;;
    --no-commit*)
      COMMIT_MODE="skip"
      ARGS=$(echo "$ARGS" | sed 's|^--no-commit[[:space:]]*||')
      ;;
    --commit*)
      COMMIT_MODE="force"
      ARGS=$(echo "$ARGS" | sed 's|^--commit[[:space:]]*||')
      ;;
    *)
      # Skip unknown args
      ARGS=$(echo "$ARGS" | sed 's|^[^[:space:]]*[[:space:]]*||')
      ;;
  esac
done

# Apply worktree override if provided
if [[ -n "$WORKTREE_ARG" ]]; then
  WORKTREE=$(convert_path "$WORKTREE_ARG")
  # Update paths based on new worktree
  MARKETPLACE_FILE="$WORKTREE/.claude-plugin/marketplace.json"
  METADATA_FILE="$WORKTREE/.thoughts/marketplace/latest-version-bump.yaml"
  PACKAGE_JSON="$WORKTREE/package.json"
  log_info "Worktree overridden to: $WORKTREE"
fi

log_debug "PLUGINS_ARG" "$PLUGINS_ARG"
log_debug "NO_MARKETPLACE" "$NO_MARKETPLACE"
log_debug "MARKETPLACE_ONLY" "$MARKETPLACE_ONLY"
log_debug "BUMP_VERSION" "$BUMP_VERSION"
log_debug "BUMP_MARKETPLACE_VERSION" "$BUMP_MARKETPLACE_VERSION"
log_debug "PR_NUMBER" "$PR_NUMBER"
log_debug "WORKTREE_ARG" "$WORKTREE_ARG"
log_debug "SCAN_MODE" "$SCAN_MODE"
log_debug "COMMIT_MODE" "$COMMIT_MODE"

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
  local err_file="${file}.err"

  if ! jq --arg v "$new_version" '.version = $v' "$file" > "$tmp_file" 2>"$err_file"; then
    log_error "jq failed for $file: $(cat "$err_file")"
    rm -f "$tmp_file" "$err_file"
    return 1
  fi
  rm -f "$err_file"

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
  local err_file="${file}.err"

  if ! jq --arg name "$plugin_name" --arg v "$new_version" \
    '(.plugins[] | select(.name == $name)).version = $v' "$file" > "$tmp_file" 2>"$err_file"; then
    log_error "jq failed for plugin $plugin_name: $(cat "$err_file")"
    rm -f "$tmp_file" "$err_file"
    return 1
  fi
  rm -f "$err_file"

  mv "$tmp_file" "$file"
  return 0
}

# ============================================================================
# Scan Mode - Rebuild metadata from git blame
# ============================================================================

scan_versions() {
  log_section "Scanning Versions from Git Blame"

  mkdir -p "$(dirname "$METADATA_FILE")"

  # Get marketplace version and blame
  MARKETPLACE_VERSION=$(jq -r '.version' "$MARKETPLACE_FILE")
  # Capture blame output - errors go to stderr naturally
  if ! MARKETPLACE_BLAME=$(git -C "$WORKTREE" blame -L '/\"version\":/,+1' --porcelain "$MARKETPLACE_FILE" | head -1); then
    log_warn "Failed to get blame for marketplace.json"
    MARKETPLACE_BLAME=""
  fi
  MARKETPLACE_COMMIT=$(echo "$MARKETPLACE_BLAME" | awk '{print $1}')

  if [[ -n "$MARKETPLACE_COMMIT" ]] && [[ "$MARKETPLACE_COMMIT" != "fatal:"* ]]; then
    if ! MARKETPLACE_DATETIME=$(git -C "$WORKTREE" show -s --format=%cI "$MARKETPLACE_COMMIT"); then
      MARKETPLACE_DATETIME="unknown"
    fi
  else
    MARKETPLACE_COMMIT=""
    MARKETPLACE_DATETIME="unknown"
  fi

  log_info "Marketplace: version=$MARKETPLACE_VERSION commit=$MARKETPLACE_COMMIT"

  # Build YAML with all plugins from marketplace.json
  {
    echo "# Last version bump metadata"
    echo "marketplace:"
    echo "  commit: $MARKETPLACE_COMMIT"
    echo "  datetime: \"$MARKETPLACE_DATETIME\""
    echo "  version: $MARKETPLACE_VERSION"
    echo "plugins:"

    # Get all plugins from marketplace.json
    jq -r '.plugins[] | "\(.name)|\(.source)"' "$MARKETPLACE_FILE" | while IFS='|' read -r name source; do
      PLUGIN_JSON="$WORKTREE/${source#./}/.claude-plugin/plugin.json"
      if [[ -f "$PLUGIN_JSON" ]]; then
        VERSION=$(jq -r '.version' "$PLUGIN_JSON")
        # Capture blame output - errors go to stderr naturally
        if ! BLAME=$(git -C "$WORKTREE" blame -L '/\"version\":/,+1' --porcelain "$PLUGIN_JSON" | head -1); then
          BLAME=""
        fi
        COMMIT=$(echo "$BLAME" | awk '{print $1}')

        if [[ -n "$COMMIT" ]] && [[ "$COMMIT" != "fatal:"* ]]; then
          if ! DATETIME=$(git -C "$WORKTREE" show -s --format=%cI "$COMMIT"); then
            DATETIME="unknown"
          fi
        else
          COMMIT=""
          DATETIME="unknown"
        fi

        log_info "Plugin $name: version=$VERSION commit=$COMMIT"

        echo "  $name:"
        echo "    commit: $COMMIT"
        echo "    datetime: \"$DATETIME\""
        echo "    version: $VERSION"
      fi
    done
  } > "$METADATA_FILE"

  log_info "Metadata rebuilt: $METADATA_FILE"
  log_exit 0 "metadata rebuilt from git blame"
  echo "{\"decision\": \"block\", \"reason\": \"Metadata file rebuilt from git blame.\"}"
  exit 0
}

# Early exit if scan mode
if [[ "$SCAN_MODE" == "true" ]]; then
  scan_versions
fi

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

    # Check for top-level commit (legacy) or marketplace commit (new format)
    LAST_COMMIT=$(yq -r '.commit // .marketplace.commit // ""' "$METADATA_FILE" || echo "")
    log_debug "LAST_COMMIT" "$LAST_COMMIT"

    if [[ -n "$LAST_COMMIT" ]]; then
      # Check if HEAD is the same as last bump commit
      HEAD_COMMIT=$(git -C "$WORKTREE" rev-parse HEAD || echo "")
      log_debug "HEAD_COMMIT" "$HEAD_COMMIT"

      if [[ "$HEAD_COMMIT" == "$LAST_COMMIT"* ]] || [[ "$LAST_COMMIT" == "$HEAD_COMMIT"* ]]; then
        # Check for uncommitted changes
        UNCOMMITTED=$(git -C "$WORKTREE" status --porcelain | grep -v '^\?\?' | head -1 || true)
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
    # Capture stdout for JSON, let stderr flow to terminal for visibility
    DETECTION_RESULT=$(bash "$DETECT_SCRIPT" "$PR_NUMBER" "$WORKTREE")
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
    DETECTED_PLUGINS=$(echo "$DETECTION_RESULT" | jq -r '.affectedPlugins[].name' | tr '\n' ',' | sed 's/,$//')
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
    PLUGIN_SOURCE=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .source' "$MARKETPLACE_FILE")
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
    CURRENT_VERSION=$(jq -r '.version // "0.0.0"' "$PLUGIN_JSON")
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

MARKETPLACE_CURRENT_VERSION=$(jq -r '.version // "0.0.0"' "$MARKETPLACE_FILE")
MARKETPLACE_NEW_VERSION=$(bump_version "$MARKETPLACE_CURRENT_VERSION" "$BUMP_MARKETPLACE_VERSION")

log_debug "Marketplace: $MARKETPLACE_CURRENT_VERSION -> $MARKETPLACE_NEW_VERSION" ""

PACKAGE_CURRENT_VERSION=""
PACKAGE_NEW_VERSION=""
if [[ -f "$PACKAGE_JSON" ]]; then
  PACKAGE_CURRENT_VERSION=$(jq -r '.version // ""' "$PACKAGE_JSON")
  if [[ -n "$PACKAGE_CURRENT_VERSION" ]]; then
    PACKAGE_NEW_VERSION=$(bump_version "$PACKAGE_CURRENT_VERSION" "$BUMP_MARKETPLACE_VERSION")
    log_debug "Package.json: $PACKAGE_CURRENT_VERSION -> $PACKAGE_NEW_VERSION" ""
  fi
fi

# ============================================================================
# Determine commit mode
# ============================================================================

determine_commit_mode() {
  log_section "Commit Mode Detection"

  # Explicit flags take precedence
  if [[ "$COMMIT_MODE" == "force" ]]; then
    log_info "Commit mode: forced by --commit"
    WILL_COMMIT=true
    return
  fi
  if [[ "$COMMIT_MODE" == "skip" ]]; then
    log_info "Commit mode: skipped by --no-commit"
    WILL_COMMIT=false
    return
  fi

  # Auto-detect: check for uncommitted tracked changes beyond version files
  log_info "Auto-detecting commit mode..."

  # Get list of tracked changed files (exclude untracked with ??)
  CHANGED=$(git -C "$WORKTREE" status --porcelain | grep -v '^\?\?' || true)

  if [[ -z "$CHANGED" ]]; then
    log_info "No tracked changes, will commit after version bump"
    WILL_COMMIT=true
    return
  fi

  # Build list of expected version files (relative to worktree)
  EXPECTED_FILES=()
  EXPECTED_FILES+=(".claude-plugin/marketplace.json")
  EXPECTED_FILES+=("package.json")
  EXPECTED_FILES+=(".thoughts/marketplace/latest-version-bump.yaml")

  # Add plugin.json files for all plugins in marketplace
  while IFS= read -r source; do
    [[ -z "$source" ]] && continue
    EXPECTED_FILES+=("${source#./}/.claude-plugin/plugin.json")
  done < <(jq -r '.plugins[].source' "$MARKETPLACE_FILE")

  log_debug "Expected version files" "${EXPECTED_FILES[*]}"

  # Check if all changed files are version files
  ALL_VERSION_FILES=true
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Handle both staged (M ) and unstaged ( M) formats - extract file path
    FILE=$(echo "$line" | sed 's/^...//')
    FOUND=false
    for exp in "${EXPECTED_FILES[@]}"; do
      if [[ "$FILE" == "$exp" ]]; then
        FOUND=true
        break
      fi
    done
    if [[ "$FOUND" != "true" ]]; then
      ALL_VERSION_FILES=false
      log_info "Non-version file changed: $FILE"
      break
    fi
  done <<< "$CHANGED"

  if [[ "$ALL_VERSION_FILES" == "true" ]]; then
    log_info "Only version files changed, will commit"
    WILL_COMMIT=true
  else
    log_info "Other files changed, will not commit"
    WILL_COMMIT=false
  fi
}

WILL_COMMIT=false
determine_commit_mode

log_debug "WILL_COMMIT" "$WILL_COMMIT"

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
# Update metadata file (preserving existing entries)
# ============================================================================

update_metadata() {
  log_section "Updating Metadata"
  mkdir -p "$(dirname "$METADATA_FILE")"

  TIMESTAMP=$(date -Iseconds)

  # Determine commit value based on WILL_COMMIT flag
  # If we will commit, we'll update this after commit with actual commit SHA
  # For now, leave empty if not committing
  if [[ "$WILL_COMMIT" == "true" ]]; then
    # Will be updated after commit
    COMMIT_VALUE="pending"
  else
    COMMIT_VALUE=""
  fi

  # Get list of all plugins from marketplace.json
  ALL_PLUGINS=$(jq -r '.plugins[].name' "$MARKETPLACE_FILE")

  # Cache existing metadata BEFORE writing (redirect truncates file first!)
  declare -A CACHED_PLUGIN_COMMIT
  declare -A CACHED_PLUGIN_DATETIME
  declare -A CACHED_PLUGIN_VERSION
  CACHED_MKT_COMMIT=""
  CACHED_MKT_DATETIME=""
  CACHED_MKT_VERSION=""

  if [[ -f "$METADATA_FILE" ]]; then
    log_info "Caching existing metadata before rewrite"
    # Cache marketplace - yq -e sets exit code, redirect stdout only
    if yq -e '.marketplace' "$METADATA_FILE" >/dev/null; then
      CACHED_MKT_COMMIT=$(yq -r '.marketplace.commit // ""' "$METADATA_FILE")
      CACHED_MKT_DATETIME=$(yq -r '.marketplace.datetime // "unknown"' "$METADATA_FILE")
      CACHED_MKT_VERSION=$(yq -r '.marketplace.version // "unknown"' "$METADATA_FILE")
      log_debug "CACHED_MKT" "$CACHED_MKT_COMMIT / $CACHED_MKT_DATETIME / $CACHED_MKT_VERSION"
    fi
    # Cache plugins
    for plugin_name in $ALL_PLUGINS; do
      if yq -e ".plugins.$plugin_name" "$METADATA_FILE" >/dev/null; then
        CACHED_PLUGIN_COMMIT["$plugin_name"]=$(yq -r ".plugins.$plugin_name.commit // \"\"" "$METADATA_FILE")
        CACHED_PLUGIN_DATETIME["$plugin_name"]=$(yq -r ".plugins.$plugin_name.datetime // \"unknown\"" "$METADATA_FILE")
        CACHED_PLUGIN_VERSION["$plugin_name"]=$(yq -r ".plugins.$plugin_name.version // \"unknown\"" "$METADATA_FILE")
        log_debug "CACHED_PLUGIN $plugin_name" "${CACHED_PLUGIN_COMMIT[$plugin_name]}"
      fi
    done
  fi

  # Build new YAML using cached values
  {
    echo "# Last version bump metadata"

    # Marketplace section
    echo "marketplace:"
    if [[ "$NO_MARKETPLACE" != "true" ]]; then
      echo "  commit: $COMMIT_VALUE"
      echo "  datetime: \"$TIMESTAMP\""
      echo "  version: $MARKETPLACE_NEW_VERSION"
    else
      # Preserve existing marketplace entry from cache
      if [[ -n "$CACHED_MKT_VERSION" ]] && [[ "$CACHED_MKT_VERSION" != "unknown" ]]; then
        echo "  commit: $CACHED_MKT_COMMIT"
        echo "  datetime: \"$CACHED_MKT_DATETIME\""
        echo "  version: $CACHED_MKT_VERSION"
      else
        # No cached value, read from marketplace.json
        MKT_VER=$(jq -r '.version' "$MARKETPLACE_FILE")
        echo "  commit: "
        echo "  datetime: \"unknown\""
        echo "  version: $MKT_VER"
      fi
    fi

    echo "plugins:"

    for plugin_name in $ALL_PLUGINS; do
      # Check if this plugin was bumped (it's in DETECTED_PLUGINS)
      if [[ -n "$DETECTED_PLUGINS" ]] && echo ",$DETECTED_PLUGINS," | grep -q ",$plugin_name,"; then
        # Use new values
        echo "  $plugin_name:"
        echo "    commit: $COMMIT_VALUE"
        echo "    datetime: \"$TIMESTAMP\""
        echo "    version: ${PLUGIN_NEW_VERSIONS[$plugin_name]}"
      else
        # Preserve existing from cache or get from plugin.json
        if [[ -n "${CACHED_PLUGIN_VERSION[$plugin_name]:-}" ]]; then
          echo "  $plugin_name:"
          echo "    commit: ${CACHED_PLUGIN_COMMIT[$plugin_name]}"
          echo "    datetime: \"${CACHED_PLUGIN_DATETIME[$plugin_name]}\""
          echo "    version: ${CACHED_PLUGIN_VERSION[$plugin_name]}"
        else
          # Read from plugin.json
          PLUGIN_SOURCE=$(jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .source' "$MARKETPLACE_FILE")
          PLUGIN_JSON="$WORKTREE/${PLUGIN_SOURCE#./}/.claude-plugin/plugin.json"
          if [[ -f "$PLUGIN_JSON" ]]; then
            VER=$(jq -r '.version' "$PLUGIN_JSON")
            echo "  $plugin_name:"
            echo "    commit: "
            echo "    datetime: \"unknown\""
            echo "    version: $VER"
          fi
        fi
      fi
    done
  } > "$METADATA_FILE"

  MODIFIED_FILES+=("$METADATA_FILE")
  log_info "Metadata updated: $METADATA_FILE"
}

update_metadata

# ============================================================================
# Execute commit if WILL_COMMIT is true
# ============================================================================

COMMIT_OUTPUT=""

execute_commit() {
  if [[ "$WILL_COMMIT" != "true" ]]; then
    log_info "Skipping commit (WILL_COMMIT=false)"
    return
  fi

  log_section "Committing Version Bump"

  # Stage version files (skip gitignored metadata - it's just a local cache)
  local add_output=""
  for f in "${MODIFIED_FILES[@]}"; do
    # Convert absolute path to relative for git add
    REL_PATH="${f#$WORKTREE/}"
    # Skip metadata file - it's gitignored
    if [[ "$REL_PATH" == ".thoughts/"* ]]; then
      log_debug "Skipping gitignored" "$REL_PATH"
      continue
    fi
    add_output=$(git -C "$WORKTREE" add "$REL_PATH" 2>&1) || true
    if [[ -n "$add_output" ]]; then
      log_debug "git add output" "$add_output"
    fi
    log_debug "Staged" "$REL_PATH"
  done

  # Create commit message
  COMMIT_MSG="chore(release): bump versions"
  if [[ -n "$DETECTED_PLUGINS" ]]; then
    COMMIT_MSG="$COMMIT_MSG ($DETECTED_PLUGINS)"
  fi

  # Commit - capture output to avoid polluting stdout before JSON response
  COMMIT_OUTPUT=$(git -C "$WORKTREE" commit -m "$COMMIT_MSG" 2>&1)
  COMMIT_RESULT=$?

  if [[ $COMMIT_RESULT -eq 0 ]]; then
    log_info "Committed: $COMMIT_MSG"
    log_debug "Commit output" "$COMMIT_OUTPUT"

    # Get actual commit SHA and update metadata (local cache only, not in git)
    ACTUAL_COMMIT=$(git -C "$WORKTREE" rev-parse HEAD)
    log_info "Commit SHA: $ACTUAL_COMMIT"

    # Update metadata with actual commit SHA
    if [[ -f "$METADATA_FILE" ]]; then
      sed -i "s/commit: pending/commit: $ACTUAL_COMMIT/g" "$METADATA_FILE"
      log_info "Updated metadata with commit SHA"
    fi
  else
    log_error "Commit failed"
    WILL_COMMIT=false
  fi
}

execute_commit

# ============================================================================
# Output JSON blocking response
# ============================================================================

log_section "Output"

# Build summary for reason
SUMMARY="Versions bumped:"
if [[ "$MARKETPLACE_ONLY" != "true" ]] && [[ -n "$DETECTED_PLUGINS" ]]; then
  IFS=',' read -ra PLUGIN_ARRAY <<< "$DETECTED_PLUGINS"
  for plugin in "${PLUGIN_ARRAY[@]}"; do
    plugin=$(echo "$plugin" | xargs)
    SUMMARY="$SUMMARY $plugin (${PLUGIN_CURRENT_VERSIONS[$plugin]} -> ${PLUGIN_NEW_VERSIONS[$plugin]})"
  done
fi
if [[ "$NO_MARKETPLACE" != "true" ]]; then
  SUMMARY="$SUMMARY, marketplace ($MARKETPLACE_CURRENT_VERSION -> $MARKETPLACE_NEW_VERSION)"
fi

if [[ "$WILL_COMMIT" == "true" ]] && [[ -n "$COMMIT_OUTPUT" ]]; then
  SUMMARY="$SUMMARY. Committed: $COMMIT_OUTPUT"
elif [[ "$WILL_COMMIT" == "true" ]]; then
  SUMMARY="$SUMMARY. Committed."
fi

# Escape for valid JSON: backslashes first, then quotes, then newlines
# Order matters: escape backslashes before adding new ones
SUMMARY_ESCAPED=$(printf '%s' "$SUMMARY" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | tr '\r' ' ')

log_exit 0 "versions bumped - block with JSON"
echo "{\"decision\": \"block\", \"reason\": \"$SUMMARY_ESCAPED\"}"
exit 0
