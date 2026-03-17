#!/bin/bash
# Inject PR metadata as Additional Context for gitx agents invoked via Task
# Called by gitx-pre-task.sh for Task calls to metadata-consuming agents

set -uo pipefail
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/hook-output.sh"
log_init "inject-pr-metadata"
export HOOK_EVENT_TYPE="PreToolUse"

# Read input
INPUT="$1"  # Passed as argument from gitx-pre-task.sh

TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
AGENT_TYPE=$(echo "$TOOL_INPUT" | jq -r '.subagent_type // ""')
PROMPT=$(echo "$TOOL_INPUT" | jq -r '.prompt // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Check if prompt already has <pr-metadata>
if echo "$PROMPT" | grep -q '<pr-metadata>'; then
  log_info "Prompt already contains pr-metadata, passing through"
  exit 0
fi

# Parse worktree from prompt: <worktree>path</worktree> or --worktree path
WORKTREE=$(echo "$PROMPT" | grep -oP '<worktree>[^<]+</worktree>' | sed 's/<[^>]*>//g')
if [[ -z "$WORKTREE" ]]; then
  WORKTREE=$(echo "$PROMPT" | grep -oP '(?<=--worktree\s)[^\s]+')
fi
if [[ -z "$WORKTREE" ]]; then
  # Convert CWD
  WORKTREE=$(echo "$CWD" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g')
fi

METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"

# Lazy fetch if metadata doesn't exist
if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "Metadata not found, lazy fetching..."
  bash "$SCRIPTS_DIR/handlers/metadata-operations.sh" fetch "$WORKTREE" >/dev/null 2>&1
fi

if [[ ! -f "$METADATA_FILE" ]]; then
  log_info "No metadata after fetch, blocking"
  hook_output_block "No PR metadata found. Use /gitx:pr to create a PR first."
  exit 0
fi

# Check for noPr indicator
NO_PR=$(yq -r '.noPr // false' "$METADATA_FILE")
if [[ "$NO_PR" == "true" ]]; then
  log_info "noPr flag set, blocking"
  hook_output_block "No open PR found for current branch. Use /gitx:pr to create one."
  exit 0
fi

# Extract per-agent fields
case "$AGENT_TYPE" in
  gitx:address-review:review-responder)
    PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
    BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
    REVIEW_COUNT=$(yq -r '.reviewCount // 0' "$METADATA_FILE")
    RESOLVE_LEVEL=$(yq -r '.resolveLevel // "all"' "$METADATA_FILE")
    LATEST_REVIEWS=$(yq -o json '.latestReviews // []' "$METADATA_FILE")

    hook_output_context "<pr-metadata>
<pr>$PR</pr>
<branch>$BRANCH</branch>
<review-count>$REVIEW_COUNT</review-count>
<resolve-level>$RESOLVE_LEVEL</resolve-level>
<latest-reviews>
$LATEST_REVIEWS
</latest-reviews>
</pr-metadata>"
    ;;

  gitx:address-review:ci-status-checker)
    PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
    BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
    CI_STATUS=$(yq -o json '.ciStatus // []' "$METADATA_FILE")
    LATEST_COMMIT=$(yq -r '.latestCommit // ""' "$METADATA_FILE")

    hook_output_context "<pr-metadata>
<pr>$PR</pr>
<branch>$BRANCH</branch>
<ci-status>
$CI_STATUS
</ci-status>
<latest-commit>$LATEST_COMMIT</latest-commit>
</pr-metadata>"
    ;;

  gitx:pr:updater)
    PR=$(yq -r '.pr // "null"' "$METADATA_FILE")
    BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE")
    BASE=$(yq -r '.base // ""' "$METADATA_FILE")
    TITLE=$(yq -r '.title // ""' "$METADATA_FILE")
    DESCRIPTION=$(yq -r '.description // ""' "$METADATA_FILE")

    hook_output_context "<pr-metadata>
<pr>$PR</pr>
<branch>$BRANCH</branch>
<base>$BASE</base>
<title>$TITLE</title>
<description>
$DESCRIPTION
</description>
</pr-metadata>"
    ;;

  *)
    log_info "No metadata mapping for agent: $AGENT_TYPE"
    ;;
esac

exit 0
