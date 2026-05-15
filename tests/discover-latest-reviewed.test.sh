#!/bin/bash
# Tests for gitx/scripts/reviews/discover-latest-reviewed.sh
# Run: bash tests/discover-latest-reviewed.test.sh
#
# Strategy: shadow `gh` with a mock on PATH and feed the script different
# GraphQL responses. Verify the JSON output for each surface, fallback path,
# and manual override.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DISCOVER_SCRIPT="$REPO_ROOT/gitx/scripts/reviews/discover-latest-reviewed.sh"
PLUGIN_ROOT="$REPO_ROOT/gitx"

TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0; FAILURES=()

pass() { ((TESTS_RUN++)); ((TESTS_PASSED++)); printf "  PASS: %s\n" "$1"; }
fail() { ((TESTS_RUN++)); ((TESTS_FAILED++)); FAILURES+=("$1: $2"); printf "  FAIL: %s -- %s\n" "$1" "$2"; }
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then pass "$desc"
  else fail "$desc" "expected '$expected', got '$actual'"; fi
}

# Mock `gh` and `git`. Each test sets MOCK_GH_RESPONSE then runs the script.
MOCK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/discover-test-XXXXXX")
cleanup() { rm -rf "$MOCK_DIR"; }
trap cleanup EXIT

cat > "$MOCK_DIR/gh" <<'EOF'
#!/bin/bash
# Mock: emit the contents of $MOCK_GH_RESPONSE on stdout; exit 0.
if [[ "$1" == "api" && "$2" == "graphql" ]]; then
  printf '%s' "${MOCK_GH_RESPONSE:-}"
  exit 0
fi
exit 1
EOF
chmod +x "$MOCK_DIR/gh"

# Mock git that returns the input "head_sha^" as a fake commit
cat > "$MOCK_DIR/git" <<'EOF'
#!/bin/bash
# Pass through to real git, except for log lookups we want to stub
if [[ "$1" == "-C" ]]; then
  shift 2
fi
if [[ "$1" == "log" && "$2" =~ \^$ ]]; then
  # Return "<sha>-parent" for parent lookups (so we can verify behavior)
  sha="${2%^}"
  echo "${sha}parent"
  exit 0
fi
# For anything else, do nothing (return empty)
exit 0
EOF
chmod +x "$MOCK_DIR/git"

export PATH="$MOCK_DIR:$PATH"

# Helper: run discover script and return stdout
run_discover() {
  local response="$1"
  shift
  MOCK_GH_RESPONSE="$response" bash "$DISCOVER_SCRIPT" \
    --plugin-root "$PLUGIN_ROOT" \
    "$@" 2>/dev/null
}

# ============================================================================
# Test 1: manual override always wins
# ============================================================================
printf "\n=== manual override ===\n"
result=$(run_discover '' --repo owner/repo --pr 1 --latest-reviewed-commit "abc123def456")
source=$(echo "$result" | jq -r '.source')
lrc=$(echo "$result" | jq -r '.latest_reviewed_commit')
assert_eq "manual source" "manual" "$source"
assert_eq "manual sha passed through" "abc123def456" "$lrc"

# ============================================================================
# Test 2: marker found in reviews surface
# ============================================================================
printf "\n=== marker in reviews ===\n"
HEX40_A=$(printf 'a%.0s' {1..40})
HEX40_B=$(printf 'b%.0s' {1..40})

response=$(jq -nc \
  --arg head "$HEX40_A" \
  --arg base "$HEX40_B" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [
        {
          id: "r1",
          body: ("<!-- claudius-review:v=1:head_sha=" + $head + ":base_sha=" + $base + ":round=2:posted_at=2026-01-01T00:00:00Z -->\n\nReview body."),
          submittedAt: "2026-01-01T00:00:00Z",
          isMinimized: false,
          commit: { oid: $head }
        }
      ] },
      comments: { nodes: [] },
      reviewThreads: { nodes: [] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
head_sha=$(echo "$result" | jq -r '.head_sha')
round=$(echo "$result" | jq -r '.round')
assert_eq "reviews source" "reviews" "$source"
assert_eq "reviews head_sha" "$HEX40_A" "$head_sha"
assert_eq "reviews round" "2" "$round"

# ============================================================================
# Test 3: marker found in top-level comments (paste-as-comment scenario)
# ============================================================================
printf "\n=== marker in comments ===\n"
response=$(jq -nc \
  --arg head "$HEX40_A" \
  --arg base "$HEX40_B" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [] },
      comments: { nodes: [
        {
          id: "c1",
          body: ("<!-- claudius-review:v=1:head_sha=" + $head + ":base_sha=" + $base + ":round=3:posted_at=2026-02-01T00:00:00Z -->"),
          createdAt: "2026-02-01T00:00:00Z"
        }
      ] },
      reviewThreads: { nodes: [] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
round=$(echo "$result" | jq -r '.round')
assert_eq "comments source" "comments" "$source"
assert_eq "comments round" "3" "$round"

# ============================================================================
# Test 4: marker found in review thread reply
# ============================================================================
printf "\n=== marker in reviewThreads ===\n"
response=$(jq -nc \
  --arg head "$HEX40_A" \
  --arg base "$HEX40_B" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [] },
      comments: { nodes: [] },
      reviewThreads: { nodes: [
        { comments: { nodes: [
          {
            id: "tc1",
            body: ("Reply text\n<!-- claudius-review:v=1:head_sha=" + $head + ":base_sha=" + $base + ":round=4:posted_at=2026-03-01T00:00:00Z -->"),
            createdAt: "2026-03-01T00:00:00Z"
          }
        ] } }
      ] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
round=$(echo "$result" | jq -r '.round')
assert_eq "threads source" "threads" "$source"
assert_eq "threads round" "4" "$round"

# ============================================================================
# Test 5: latest timestamp wins across surfaces
# ============================================================================
printf "\n=== latest timestamp wins ===\n"
response=$(jq -nc \
  --arg head "$HEX40_A" \
  --arg base "$HEX40_B" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [
        {
          id: "r1",
          body: ("<!-- claudius-review:v=1:head_sha=" + $head + ":base_sha=" + $base + ":round=1:posted_at=2026-01-01T00:00:00Z -->"),
          submittedAt: "2026-01-01T00:00:00Z",
          isMinimized: false,
          commit: { oid: $head }
        }
      ] },
      comments: { nodes: [
        {
          id: "c1",
          body: ("<!-- claudius-review:v=1:head_sha=" + $head + ":base_sha=" + $base + ":round=5:posted_at=2026-04-01T00:00:00Z -->"),
          createdAt: "2026-04-01T00:00:00Z"
        }
      ] },
      reviewThreads: { nodes: [] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
round=$(echo "$result" | jq -r '.round')
assert_eq "latest wins source" "comments" "$source"
assert_eq "latest wins round" "5" "$round"

# ============================================================================
# Test 6: fallback to reviews-only heuristic when no marker found
# ============================================================================
printf "\n=== fallback when no marker ===\n"
response=$(jq -nc \
  --arg head "$HEX40_A" \
  --arg base "$HEX40_B" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [
        {
          id: "r1",
          body: "Round 7\n\nLegacy review body without marker.",
          submittedAt: "2026-05-01T00:00:00Z",
          isMinimized: false,
          commit: { oid: $head }
        }
      ] },
      comments: { nodes: [] },
      reviewThreads: { nodes: [] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
round=$(echo "$result" | jq -r '.round')
head_sha=$(echo "$result" | jq -r '.head_sha')
assert_eq "fallback source is none" "none" "$source"
assert_eq "fallback round parsed from body" "7" "$round"
assert_eq "fallback head_sha from headRefOid" "$HEX40_A" "$head_sha"

# ============================================================================
# Test 7: nothing at all
# ============================================================================
printf "\n=== empty PR ===\n"
response=$(jq -nc \
  --arg head "$HEX40_A" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [] },
      comments: { nodes: [] },
      reviewThreads: { nodes: [] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
lrc=$(echo "$result" | jq -r '.latest_reviewed_commit')
assert_eq "empty PR source none" "none" "$source"
assert_eq "empty PR lrc empty" "" "$lrc"

# ============================================================================
# Test 8: minimized reviews are ignored
# ============================================================================
printf "\n=== minimized reviews ignored ===\n"
response=$(jq -nc \
  --arg head "$HEX40_A" \
  --arg base "$HEX40_B" \
  '{
    data: { repository: { pullRequest: {
      headRefOid: $head,
      reviews: { nodes: [
        {
          id: "r1",
          body: ("<!-- claudius-review:v=1:head_sha=" + $head + ":base_sha=" + $base + ":round=9:posted_at=2026-06-01T00:00:00Z -->"),
          submittedAt: "2026-06-01T00:00:00Z",
          isMinimized: true,
          commit: { oid: $head }
        }
      ] },
      comments: { nodes: [] },
      reviewThreads: { nodes: [] }
    } } }
  }')

result=$(run_discover "$response" --repo owner/repo --pr 1)
source=$(echo "$result" | jq -r '.source')
assert_eq "minimized review excluded" "none" "$source"

# ============================================================================
# Summary
# ============================================================================
printf "\n========================================\n"
printf "Tests run: %d, passed: %d, failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
if [[ ${#FAILURES[@]} -gt 0 ]]; then
  printf "\nFailures:\n"
  for f in "${FAILURES[@]}"; do printf "  - %s\n" "$f"; done
  exit 1
fi
exit 0
