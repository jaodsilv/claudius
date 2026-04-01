#!/bin/bash
# PR metadata operations with flag-based CLI
# Usage: metadata-operations.sh [--worktree <path>] [--get [<fields>]] [--set <key> <value>]* ...

# Parse --plugin-root flag
for _arg in "$@"; do
  if [[ "$_arg" == --plugin-root=* ]]; then
    _PLUGIN_ROOT_PARAM="${_arg#--plugin-root=}"
    break
  fi
done

# Priority: env var > --plugin-root flag > self-location fallback
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${_PLUGIN_ROOT_PARAM:-$(cd "$(dirname "$0")/../.." && pwd)}}"

set -uo pipefail

SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks/scripts"
source "$SCRIPTS_DIR/lib/logging.sh"
source "$SCRIPTS_DIR/lib/args-helper.sh"

# ---------------------------------------------------------------------------
# Field registries
# ---------------------------------------------------------------------------
ALL_FIELDS=(pr author branch worktree title description base linkedIssue
  latestReviews reviewThreads latestMinimizedReview latestReviewedCommit
  ciStatus ciResult latestComments historicalComments reviewCount turn
  latestCommit reviewDecision approved resolveLevel createdAt updatedAt)

REFRESHABLE_FIELDS=(pr author title description branch base linkedIssue
  worktree latestReviews reviewThreads latestMinimizedReview
  latestReviewedCommit reviewCount latestCommit ciStatus ciResult
  latestComments historicalComments turn)

NON_REFRESHABLE_FIELDS=(createdAt reviewDecision approved resolveLevel)

SETTABLE_FIELDS=(turn approved resolveLevel)

AREAS=(no-pr pr issue worktree review comments ci turn)

# Area-to-fields mapping
get_area_fields() {
  case "$1" in
    no-pr)    echo "branch latestCommit linkedIssue base author pr" ;;
    pr)       echo "pr author title description branch base" ;;
    issue)    echo "linkedIssue" ;;
    worktree) echo "worktree branch" ;;
    review)   echo "latestReviews reviewThreads latestMinimizedReview latestReviewedCommit reviewCount latestCommit" ;;
    comments) echo "latestComments historicalComments" ;;
    ci)       echo "ciStatus ciResult" ;;
    turn)     echo "ciStatus ciResult latestComments historicalComments turn" ;;
    *)        echo "" ;;
  esac
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
WORKTREE="."
FORMAT=""
OUTPUT_FILE=""
DO_GET=false
GET_FIELDS=""
DO_REFRESH=false
REFRESH_FIELDS=""
REFRESH_AREAS=""
DO_WAIT_CI=false
CLEAR_FIELDS=""
SHOW_FIELDS=false
SHOW_AREAS=false
SHOW_SET_FIELDS=false

# Collect --set pairs
declare -a SET_KEYS=()
declare -a SET_VALUES=()

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin-root=*)
      shift
      ;;
    --worktree)
      WORKTREE="${2:-.}"
      shift 2
      ;;
    --get)
      DO_GET=true
      shift
      # Check if next arg is a field list (not another flag)
      if [[ $# -gt 0 ]] && [[ "$1" != --* ]]; then
        GET_FIELDS="$1"
        shift
      fi
      ;;
    --set)
      if [[ $# -lt 3 ]]; then
        echo '{"error": "--set requires <key> <value>"}' >&2
        exit 1
      fi
      SET_KEYS+=("$2")
      SET_VALUES+=("$3")
      shift 3
      ;;
    --clear)
      if [[ $# -lt 2 ]]; then
        echo '{"error": "--clear requires <fields>"}' >&2
        exit 1
      fi
      CLEAR_FIELDS="$2"
      shift 2
      ;;
    --refresh)
      DO_REFRESH=true
      shift
      if [[ $# -gt 0 ]] && [[ "$1" != --* ]]; then
        REFRESH_FIELDS="$1"
        shift
      fi
      ;;
    --refresh-areas)
      DO_REFRESH=true
      if [[ $# -lt 2 ]]; then
        echo '{"error": "--refresh-areas requires <areas>"}' >&2
        exit 1
      fi
      REFRESH_AREAS="$2"
      shift 2
      ;;
    --format)
      if [[ $# -lt 2 ]]; then
        echo '{"error": "--format requires <json|yaml>"}' >&2
        exit 1
      fi
      FORMAT="$2"
      shift 2
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo '{"error": "--output requires <filepath>"}' >&2
        exit 1
      fi
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --fields)
      SHOW_FIELDS=true
      shift
      ;;
    --areas)
      SHOW_AREAS=true
      shift
      ;;
    --set-fields)
      SHOW_SET_FIELDS=true
      shift
      ;;
    --wait-ci)
      DO_WAIT_CI=true
      shift
      ;;
    *)
      echo "{\"error\": \"Unknown flag: $1\"}" >&2
      exit 1
      ;;
  esac
done

# Resolve worktree path
WORKTREE=$(resolve_path "$(convert_path "$WORKTREE")" "$(pwd)")
METADATA_FILE="$WORKTREE/.thoughts/pr/metadata.yaml"

# ---------------------------------------------------------------------------
# Step 1: Info commands (print and exit)
# ---------------------------------------------------------------------------
if [[ "$SHOW_FIELDS" == "true" ]]; then
  printf '%s\n' "${ALL_FIELDS[@]}"
  exit 0
fi

if [[ "$SHOW_AREAS" == "true" ]]; then
  printf '%s\n' "${AREAS[@]}"
  exit 0
fi

if [[ "$SHOW_SET_FIELDS" == "true" ]]; then
  if [[ ! -f "$METADATA_FILE" ]]; then
    echo '{"error": "Metadata not found"}' >&2
    exit 1
  fi
  # List fields that have non-null values
  yq -r 'to_entries[] | select(.value != null) | .key' "$METADATA_FILE"
  exit 0
fi

# ---------------------------------------------------------------------------
# Step 2: --wait-ci (polling loop)
# ---------------------------------------------------------------------------
if [[ "$DO_WAIT_CI" == "true" ]]; then
  BRANCH=""
  if [[ -f "$METADATA_FILE" ]]; then
    BRANCH=$(yq -r '.branch // ""' "$METADATA_FILE" 2>/dev/null)
  fi
  if [[ -z "$BRANCH" ]]; then
    BRANCH=$(git -C "$WORKTREE" branch --show-current 2>/dev/null || echo "")
  fi
  if [[ -z "$BRANCH" ]]; then
    echo '{"error": "Could not determine branch"}' >&2
    exit 1
  fi

  MAX_WAIT=600
  ELAPSED=0
  while [[ $ELAPSED -lt $MAX_WAIT ]]; do
    PENDING=$(gh run list -b "$BRANCH" --json status --jq '[.[] | select(.status != "completed")] | length' || echo "0")
    if [[ "$PENDING" == "0" ]]; then
      echo '{"status": "ok", "branch": "'"$BRANCH"'", "waited": '$ELAPSED'}'
      # Fall through to refresh/get/set if other flags present
      break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
  done
  if [[ $ELAPSED -ge $MAX_WAIT ]]; then
    echo '{"status": "timeout", "branch": "'"$BRANCH"'", "waited": '$ELAPSED'}'
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Step 3: --refresh / --refresh-areas (calls fetch-pr-metadata.sh)
# ---------------------------------------------------------------------------
if [[ "$DO_REFRESH" == "true" ]]; then
  FETCH_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/metadata/fetch-pr-metadata.sh"
  if [[ ! -f "$FETCH_SCRIPT" ]]; then
    echo '{"error": "fetch-pr-metadata.sh not found at '"$FETCH_SCRIPT"'"}' >&2
    exit 1
  fi
  # Always do a full refresh (selective refresh would require modular fetch)
  bash "$FETCH_SCRIPT" "$WORKTREE"
fi

# ---------------------------------------------------------------------------
# Step 4: --get (output fields)
# ---------------------------------------------------------------------------
if [[ "$DO_GET" == "true" ]]; then
  if [[ ! -f "$METADATA_FILE" ]]; then
    echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
    exit 1
  fi

  # Determine output format
  _format="${FORMAT:-json}"

  if [[ -z "$GET_FIELDS" ]]; then
    # No fields specified → entire metadata
    if [[ "$_format" == "yaml" ]]; then
      _output=$(cat "$METADATA_FILE")
    else
      _output=$(yq -o=json '.' "$METADATA_FILE")
    fi
  else
    # Split comma-separated fields
    IFS=',' read -ra _fields <<< "$GET_FIELDS"

    if [[ ${#_fields[@]} -eq 1 ]]; then
      # Single field → raw value (unless --format)
      if [[ -z "$FORMAT" ]]; then
        _output=$(yq -r ".${_fields[0]} // null" "$METADATA_FILE")
      elif [[ "$_format" == "yaml" ]]; then
        _output=$(yq ".${_fields[0]}" "$METADATA_FILE")
      else
        _output=$(yq -o=json ".${_fields[0]}" "$METADATA_FILE")
      fi
    else
      # Multiple fields → key-value object
      _yq_expr="{"
      for i in "${!_fields[@]}"; do
        [[ $i -gt 0 ]] && _yq_expr+=", "
        _yq_expr+="\"${_fields[$i]}\": .${_fields[$i]}"
      done
      _yq_expr+="}"

      if [[ "$_format" == "yaml" ]]; then
        _output=$(yq "$_yq_expr" "$METADATA_FILE")
      else
        _output=$(yq -o=json "$_yq_expr" "$METADATA_FILE")
      fi
    fi
  fi

  # Output to file or stdout
  if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$_output" > "$OUTPUT_FILE"
    echo '{"status": "ok", "output": "'"$OUTPUT_FILE"'"}'
  else
    echo "$_output"
  fi
fi

# ---------------------------------------------------------------------------
# Step 5: --set operations
# ---------------------------------------------------------------------------
MUTATED=false

for i in "${!SET_KEYS[@]}"; do
  _key="${SET_KEYS[$i]}"
  _val="${SET_VALUES[$i]}"

  if [[ ! -f "$METADATA_FILE" ]]; then
    echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
    exit 1
  fi

  # Validate settable fields with specific value constraints
  case "$_key" in
    turn)
      case "$_val" in
        CI-PENDING|CI-REVIEW|REVIEW|AUTHOR) ;;
        *)
          echo '{"error": "Invalid turn value. Use: CI-PENDING, CI-REVIEW, REVIEW, AUTHOR"}' >&2
          exit 1
          ;;
      esac
      yq -i ".turn = \"$_val\"" "$METADATA_FILE"
      MUTATED=true
      ;;
    approved)
      case "$_val" in
        true|false) ;;
        *)
          echo '{"error": "Invalid approved value. Use: true, false"}' >&2
          exit 1
          ;;
      esac
      yq -i ".approved = $_val" "$METADATA_FILE"
      MUTATED=true
      ;;
    resolveLevel)
      case "$_val" in
        all|critical|important) ;;
        *)
          echo '{"error": "Invalid resolve level. Use: all, critical, important"}' >&2
          exit 1
          ;;
      esac
      yq -i ".resolveLevel = \"$_val\"" "$METADATA_FILE"
      MUTATED=true
      ;;
    *)
      # Generic set for any field
      yq -i ".$_key = $_val" "$METADATA_FILE"
      MUTATED=true
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Step 6: --clear fields (always last)
# ---------------------------------------------------------------------------
if [[ -n "$CLEAR_FIELDS" ]]; then
  if [[ ! -f "$METADATA_FILE" ]]; then
    echo '{"error": "Metadata not found", "needs_fetch": true}' >&2
    exit 1
  fi

  IFS=',' read -ra _clear_fields <<< "$CLEAR_FIELDS"
  for _field in "${_clear_fields[@]}"; do
    case "$_field" in
      ciStatus)
        yq -i ".ciStatus = []" "$METADATA_FILE"
        ;;
      ciResult)
        yq -i ".ciResult = null" "$METADATA_FILE"
        ;;
      *)
        yq -i "del(.$_field)" "$METADATA_FILE"
        ;;
    esac
  done
  MUTATED=true
fi

# ---------------------------------------------------------------------------
# Step 7: Update updatedAt if any mutation occurred
# ---------------------------------------------------------------------------
if [[ "$MUTATED" == "true" ]]; then
  yq -i ".updatedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$METADATA_FILE"
  echo '{"status": "ok"}'
fi

# If no action was specified, show usage
if [[ "$DO_GET" == "false" ]] && [[ "$DO_REFRESH" == "false" ]] && [[ "$DO_WAIT_CI" == "false" ]] && \
   [[ ${#SET_KEYS[@]} -eq 0 ]] && [[ -z "$CLEAR_FIELDS" ]] && \
   [[ "$SHOW_FIELDS" == "false" ]] && [[ "$SHOW_AREAS" == "false" ]] && [[ "$SHOW_SET_FIELDS" == "false" ]]; then
  cat >&2 <<'USAGE'
Usage: metadata-operations.sh [flags]

Flags:
  --worktree <path>        Working directory (default: .)
  --get [<fields>]         Get metadata fields (comma-separated, or all)
  --set <key> <value>      Set a metadata field (repeatable)
  --clear <fields>         Clear/delete fields (comma-separated)
  --refresh [<fields>]     Refresh metadata from GitHub
  --refresh-areas <areas>  Refresh by area (comma-separated)
  --wait-ci                Wait for CI to complete (max 10 min)
  --format <json|yaml>     Output format (default: json)
  --output <filepath>      Write output to file
  --fields                 List all known fields
  --areas                  List all areas
  --set-fields             List populated fields in metadata
USAGE
  exit 1
fi
