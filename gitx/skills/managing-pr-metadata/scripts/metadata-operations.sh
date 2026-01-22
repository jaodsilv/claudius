#!/bin/bash
# PR metadata operations with lazy loading
# Usage: metadata-operations.sh <operation> <worktree> [field] [value]

set -uo pipefail

# Convert Windows paths to bash format: D:\ or D:/ -> /d/
convert_path() {
  local path="$1"
  echo "$path" | sed -E 's|^([A-Za-z]):|/\L\1|; s|\\|/|g'
}

OPERATION="${1:-}"
WORKTREE="${2:-.}"
FIELD="${3:-}"
VALUE="${4:-}"

# Convert Windows paths
WORKTREE=$(convert_path "$WORKTREE")
if [[ "$WORKTREE" == "." ]]; then
  WORKTREE=$(convert_path "$(pwd)")
fi

# Resolve relative paths to absolute
if [[ ! "$WORKTREE" = /* ]]; then
  WORKTREE=$(convert_path "$(cd "$WORKTREE" 2>/dev/null && pwd)")
fi

METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"

case "$OPERATION" in
  ensure)
    # Check if metadata exists and is valid
    if [[ -f "$METADATA_FILE" ]]; then
      has_error=$(yq -r '.error // false' "$METADATA_FILE" 2>/dev/null)
      no_pr=$(yq -r '.noPr // false' "$METADATA_FILE" 2>/dev/null)
      if [[ "$has_error" != "true" ]] && [[ "$no_pr" != "true" ]]; then
        echo '{"status": "ok", "path": "'"$METADATA_FILE"'"}'
        exit 0
      fi
    fi
    echo '{"status": "needs_fetch", "path": "'"$METADATA_FILE"'"}'
    exit 1
    ;;

  read)
    if [[ -z "$FIELD" ]]; then
      echo '{"error": "Field name required"}' >&2
      exit 1
    fi
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    yq -o=json ".$FIELD" "$METADATA_FILE"
    ;;

  update)
    if [[ -z "$FIELD" ]] || [[ -z "$VALUE" ]]; then
      echo '{"error": "Field and value required"}' >&2
      exit 1
    fi
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    yq -i ".$FIELD = $VALUE" "$METADATA_FILE"
    yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
    echo '{"status": "ok"}'
    ;;

  set-resolve-level)
    if [[ -z "$FIELD" ]]; then
      echo '{"error": "Resolve level required"}' >&2
      exit 1
    fi
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    # FIELD contains the level value (all, critical, important)
    case "$FIELD" in
      all|critical|important)
        yq -i ".resolveLevel = \"$FIELD\"" "$METADATA_FILE"
        yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
        echo '{"status": "ok", "resolveLevel": "'"$FIELD"'"}'
        ;;
      *)
        echo '{"error": "Invalid resolve level. Use: all, critical, important"}' >&2
        exit 1
        ;;
    esac
    ;;

  set-approved)
    if [[ -z "$FIELD" ]]; then
      echo '{"error": "Approved value required (true/false)"}' >&2
      exit 1
    fi
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    # FIELD contains true/false
    case "$FIELD" in
      true|false)
        yq -i ".approved = $FIELD" "$METADATA_FILE"
        yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
        echo '{"status": "ok", "approved": '"$FIELD"'}'
        ;;
      *)
        echo '{"error": "Invalid approved value. Use: true, false"}' >&2
        exit 1
        ;;
    esac
    ;;

  remove-field)
    if [[ -z "$FIELD" ]]; then
      echo '{"error": "Field name required"}' >&2
      exit 1
    fi
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    yq -i "del(.$FIELD)" "$METADATA_FILE"
    yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
    echo '{"status": "ok", "removed": "'"$FIELD"'"}'
    ;;

  fetch)
    # Determine script location relative to this script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FETCH_SCRIPT="$SCRIPT_DIR/../../../hooks/scripts/fetch-pr-metadata.sh"

    if [[ ! -f "$FETCH_SCRIPT" ]]; then
      echo '{"error": "fetch-pr-metadata.sh not found at '"$FETCH_SCRIPT"'"}' >&2
      exit 1
    fi

    bash "$FETCH_SCRIPT" "$WORKTREE"
    ;;

  post-push)
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    # Use WORKTREE directly (passed as argument), not from metadata
    LATEST=$(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null || echo "")
    if [[ -z "$LATEST" ]]; then
      echo '{"error": "Could not determine latest commit"}' >&2
      exit 1
    fi
    yq -i ".ciStatus = [] | .turn = \"CI-PENDING\" | .latestCommit = \"$LATEST\" | .updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
    echo '{"status": "ok", "turn": "CI-PENDING", "ciStatus": "cleared", "latestCommit": "'"$LATEST"'"}'
    ;;

  set-turn)
    if [[ -z "$FIELD" ]]; then
      echo '{"error": "Turn value required"}' >&2
      exit 1
    fi
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    case "$FIELD" in
      CI-PENDING|CI-REVIEW|REVIEW|AUTHOR)
        yq -i ".turn = \"$FIELD\"" "$METADATA_FILE"
        yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
        echo '{"status": "ok", "turn": "'"$FIELD"'"}'
        ;;
      *)
        echo '{"error": "Invalid turn value. Use: CI-PENDING, CI-REVIEW, REVIEW, AUTHOR"}' >&2
        exit 1
        ;;
    esac
    ;;

  clear-ci-status)
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    yq -i ".ciStatus = []" "$METADATA_FILE"
    yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
    echo '{"status": "ok", "cleared": "ciStatus"}'
    ;;

  update-latest-commit)
    if [[ ! -f "$METADATA_FILE" ]]; then
      echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
      exit 1
    fi
    # Use WORKTREE directly (passed as argument)
    LATEST=$(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null || echo "")
    if [[ -z "$LATEST" ]]; then
      echo '{"error": "Could not determine latest commit"}' >&2
      exit 1
    fi
    yq -i ".latestCommit = \"$LATEST\"" "$METADATA_FILE"
    yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
    echo '{"status": "ok", "latestCommit": "'"$LATEST"'"}'
    ;;

  *)
    echo "Usage: metadata-operations.sh <operation> <worktree> [field] [value]" >&2
    echo "" >&2
    echo "Operations:" >&2
    echo "  fetch <worktree>                     - Fetch PR metadata from GitHub" >&2
    echo "  ensure <worktree>                    - Check if metadata exists" >&2
    echo "  read <worktree> <field>              - Read a field" >&2
    echo "  update <worktree> <field> <value>    - Update a field (JSON value)" >&2
    echo "  set-resolve-level <worktree> <level> - Set resolve level" >&2
    echo "  set-approved <worktree> <bool>       - Set approved status" >&2
    echo "  set-turn <worktree> <turn>           - Set turn (CI-PENDING|CI-REVIEW|REVIEW|AUTHOR)" >&2
    echo "  remove-field <worktree> <field>      - Remove a field" >&2
    echo "  post-push <worktree>                 - Clear CI, set turn to CI-PENDING, update commit" >&2
    echo "  clear-ci-status <worktree>           - Clear ciStatus array" >&2
    echo "  update-latest-commit <worktree>      - Update latestCommit from HEAD" >&2
    exit 1
    ;;
esac
