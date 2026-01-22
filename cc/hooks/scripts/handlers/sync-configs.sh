#!/bin/bash
# Handler for /cc:sync-configs command
# Analyzes plugin.json and marketplace.json for inconsistencies

log_section "Sync-Configs Handler"

MARKETPLACE_FILE="$WORKTREE/.claude-plugin/marketplace.json"

# Parse arguments
PLUGINS_ARG=""
AUTO_FIX=false

while [[ -n "$ARGS" ]]; do
  case "$ARGS" in
    --plugins\ *)
      PLUGINS_ARG=$(echo "$ARGS" | sed -n 's|^--plugins[[:space:]]\+\([^[:space:]]*\).*|\1|p')
      ARGS=$(echo "$ARGS" | sed 's|^--plugins[[:space:]]\+[^[:space:]]*[[:space:]]*||')
      ;;
    --fix*)
      AUTO_FIX=true
      ARGS=$(echo "$ARGS" | sed 's|^--fix[[:space:]]*||')
      ;;
    *)
      ARGS=$(echo "$ARGS" | sed 's|^[^[:space:]]*[[:space:]]*||')
      ;;
  esac
done

log_debug "PLUGINS_ARG" "$PLUGINS_ARG"
log_debug "AUTO_FIX" "$AUTO_FIX"

# Check marketplace.json exists
if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  log_error "No marketplace.json found"
  log_exit 2 "no marketplace.json"
  echo "Error: marketplace.json not found at $MARKETPLACE_FILE" >&2
  exit 2
fi

# Get marketplace version
MARKETPLACE_VERSION=$(jq -r '.version // ""' "$MARKETPLACE_FILE" 2>/dev/null)
log_debug "MARKETPLACE_VERSION" "$MARKETPLACE_VERSION"

# Get list of plugins to check
if [[ -n "$PLUGINS_ARG" ]]; then
  IFS=',' read -ra PLUGINS <<< "$PLUGINS_ARG"
else
  # Get all plugins from marketplace.json
  mapfile -t PLUGINS < <(jq -r '.plugins[].name' "$MARKETPLACE_FILE" 2>/dev/null)
fi

log_debug "PLUGINS" "${PLUGINS[*]}"

# Track differences
DIFF_OUTPUT=""
HAS_DIFFERENCES=false
HIGHEST_VERSION="$MARKETPLACE_VERSION"

# Compare semantic versions (returns 0 if v1 > v2, 1 if v1 < v2, 2 if equal)
compare_versions() {
  local v1="$1"
  local v2="$2"

  # Strip any prerelease suffix for comparison
  v1="${v1%%-*}"
  v2="${v2%%-*}"

  IFS='.' read -ra V1_PARTS <<< "$v1"
  IFS='.' read -ra V2_PARTS <<< "$v2"

  for i in 0 1 2; do
    local p1="${V1_PARTS[$i]:-0}"
    local p2="${V2_PARTS[$i]:-0}"
    if (( p1 > p2 )); then
      return 0
    elif (( p1 < p2 )); then
      return 1
    fi
  done
  return 2
}

# Check each plugin
for plugin in "${PLUGINS[@]}"; do
  plugin=$(echo "$plugin" | xargs)  # trim whitespace
  [[ -z "$plugin" ]] && continue

  log_info "Checking plugin: $plugin"

  # Get plugin source from marketplace
  PLUGIN_SOURCE=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .source' "$MARKETPLACE_FILE" 2>/dev/null)

  if [[ -z "$PLUGIN_SOURCE" ]]; then
    log_warn "Plugin '$plugin' not found in marketplace.json"
    continue
  fi

  # Get marketplace entry version for this plugin
  MARKETPLACE_ENTRY_VERSION=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .version // ""' "$MARKETPLACE_FILE" 2>/dev/null)
  log_debug "MARKETPLACE_ENTRY_VERSION for $plugin" "$MARKETPLACE_ENTRY_VERSION"

  # Read plugin.json
  PLUGIN_JSON="$WORKTREE/${PLUGIN_SOURCE#./}/.claude-plugin/plugin.json"

  if [[ ! -f "$PLUGIN_JSON" ]]; then
    log_warn "Plugin '$plugin' plugin.json not found at $PLUGIN_JSON"
    DIFF_OUTPUT+="- $plugin: plugin.json not found at $PLUGIN_JSON"$'\n'
    HAS_DIFFERENCES=true
    continue
  fi

  # Get plugin.json version
  PLUGIN_JSON_VERSION=$(jq -r '.version // ""' "$PLUGIN_JSON" 2>/dev/null)
  log_debug "PLUGIN_JSON_VERSION for $plugin" "$PLUGIN_JSON_VERSION"

  # Compare versions
  PLUGIN_DIFF=""

  if [[ -n "$MARKETPLACE_ENTRY_VERSION" ]] && [[ "$MARKETPLACE_ENTRY_VERSION" != "$PLUGIN_JSON_VERSION" ]]; then
    PLUGIN_DIFF+="  Version mismatch: marketplace=$MARKETPLACE_ENTRY_VERSION, plugin.json=$PLUGIN_JSON_VERSION"$'\n'
    HAS_DIFFERENCES=true

    # Update highest version
    if compare_versions "$MARKETPLACE_ENTRY_VERSION" "$HIGHEST_VERSION"; then
      HIGHEST_VERSION="$MARKETPLACE_ENTRY_VERSION"
    fi
    if compare_versions "$PLUGIN_JSON_VERSION" "$HIGHEST_VERSION"; then
      HIGHEST_VERSION="$PLUGIN_JSON_VERSION"
    fi
  fi

  # Compare other fields: name, description
  MARKETPLACE_NAME=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .name' "$MARKETPLACE_FILE" 2>/dev/null)
  PLUGIN_JSON_NAME=$(jq -r '.name // ""' "$PLUGIN_JSON" 2>/dev/null)

  if [[ -n "$PLUGIN_JSON_NAME" ]] && [[ "$MARKETPLACE_NAME" != "$PLUGIN_JSON_NAME" ]]; then
    PLUGIN_DIFF+="  Name mismatch: marketplace=$MARKETPLACE_NAME, plugin.json=$PLUGIN_JSON_NAME"$'\n'
    HAS_DIFFERENCES=true
  fi

  MARKETPLACE_DESC=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .description // ""' "$MARKETPLACE_FILE" 2>/dev/null)
  PLUGIN_JSON_DESC=$(jq -r '.description // ""' "$PLUGIN_JSON" 2>/dev/null)

  if [[ -n "$PLUGIN_JSON_DESC" ]] && [[ "$MARKETPLACE_DESC" != "$PLUGIN_JSON_DESC" ]]; then
    # Truncate long descriptions for display
    MARKETPLACE_DESC_SHOW="${MARKETPLACE_DESC:0:50}"
    PLUGIN_JSON_DESC_SHOW="${PLUGIN_JSON_DESC:0:50}"
    [[ ${#MARKETPLACE_DESC} -gt 50 ]] && MARKETPLACE_DESC_SHOW+="..."
    [[ ${#PLUGIN_JSON_DESC} -gt 50 ]] && PLUGIN_JSON_DESC_SHOW+="..."
    PLUGIN_DIFF+="  Description mismatch: marketplace=\"$MARKETPLACE_DESC_SHOW\", plugin.json=\"$PLUGIN_JSON_DESC_SHOW\""$'\n'
    HAS_DIFFERENCES=true
  fi

  if [[ -n "$PLUGIN_DIFF" ]]; then
    DIFF_OUTPUT+="- $plugin:"$'\n'"$PLUGIN_DIFF"
  fi
done

# Also check root marketplace version vs highest plugin version
if compare_versions "$HIGHEST_VERSION" "$MARKETPLACE_VERSION"; then
  DIFF_OUTPUT+="- Root marketplace.json version ($MARKETPLACE_VERSION) is lower than highest plugin version ($HIGHEST_VERSION)"$'\n'
  HAS_DIFFERENCES=true
fi

# Output results
log_section "Output"

if [[ "$HAS_DIFFERENCES" != "true" ]]; then
  log_info "All configs in sync"
  log_exit 2 "already in sync"
  echo "All plugin configurations are in sync."
  echo "No action needed."
  exit 2
fi

echo "=== Config Sync Analysis ==="
echo ""
echo "Found the following inconsistencies:"
echo ""
echo "$DIFF_OUTPUT"
echo ""
echo "Highest version found: $HIGHEST_VERSION"
echo ""
if [[ "$AUTO_FIX" == "true" ]]; then
  echo "Mode: Auto-fix enabled"
else
  echo "Mode: Interactive (LLM will ask for confirmation)"
fi
echo ""
echo "=== Ready for config sync ==="

log_exit 0 "proceed to LLM"
exit 0
