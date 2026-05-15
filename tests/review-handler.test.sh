#!/bin/bash
# Tests for gitx/hooks/scripts/handlers/reviews/review.sh — Branch A skip-fast
# guards and tag emission.
#
# Strategy: shadow `gh` and `git` with mocks, run the full pre-command hook
# entry point with controlled stdin and ARGS, then parse the resulting JSON
# additionalContext block.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/gitx"
HOOK_ENTRY="$PLUGIN_ROOT/hooks/scripts/gitx-pre-command.sh"

TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0; FAILURES=()
pass() { ((TESTS_RUN++)); ((TESTS_PASSED++)); printf "  PASS: %s\n" "$1"; }
fail() { ((TESTS_RUN++)); ((TESTS_FAILED++)); FAILURES+=("$1: $2"); printf "  FAIL: %s -- %s\n" "$1" "$2"; }
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then pass "$desc"
  else fail "$desc" "expected '$expected', got '$actual'"; fi
}
assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then pass "$desc"
  else fail "$desc" "expected to contain '$needle'\n      in: $haystack"; fi
}

MOCK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/review-handler-test-XXXXXX")
WORKTREE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/review-handler-wt-XXXXXX")
cleanup() { rm -rf "$MOCK_DIR" "$WORKTREE_DIR"; }
trap cleanup EXIT

# Initialize a real-ish git repo for the worktree (rev-parse needs to work)
( cd "$WORKTREE_DIR" \
  && git init -q . \
  && git -c user.email=t@t -c user.name=T commit --allow-empty -q -m init >/dev/null )

# `gh` mock: pluggable per-call by setting MOCK_GH_PR_VIEW / MOCK_GH_GRAPHQL / MOCK_GH_USER
cat > "$MOCK_DIR/gh" <<'EOF'
#!/bin/bash
case "$1" in
  auth)
    exit 0 ;;
  api)
    if [[ "$2" == "graphql" ]]; then
      printf '%s' "${MOCK_GH_GRAPHQL:-{}}"
      exit 0
    fi
    if [[ "$2" == "user" ]]; then
      echo "${MOCK_GH_USER_LOGIN:-some-user}"
      exit 0
    fi
    exit 0 ;;
  pr)
    if [[ "$2" == "view" ]]; then
      printf '%s' "${MOCK_GH_PR_VIEW:-{}}"
      exit 0
    fi
    exit 0 ;;
esac
exit 0
EOF
chmod +x "$MOCK_DIR/gh"

# Use the mocks first on PATH
export PATH="$MOCK_DIR:$PATH"

# Helper: run pre-command hook with given ARGS and CI env, return raw stdout
run_hook() {
  local args="$1"
  local ci_env="${2:-}"
  local prompt="/gitx:review $args"
  local input
  input=$(jq -nc --arg cwd "$WORKTREE_DIR" --arg prompt "$prompt" '{cwd: $cwd, prompt: $prompt}')

  if [[ -n "$ci_env" ]]; then
    CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CI=1 GITHUB_ACTIONS=true bash "$HOOK_ENTRY" <<< "$input" 2>/dev/null
  else
    CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CI="" GITHUB_ACTIONS="" bash "$HOOK_ENTRY" <<< "$input" 2>/dev/null
  fi
}

HEX40_A=$(printf 'a%.0s' {1..40})
HEX40_B=$(printf 'b%.0s' {1..40})

# ============================================================================
# Test 1: closed PR → block
# ============================================================================
printf "\n=== closed PR is blocked ===\n"
export MOCK_GH_PR_VIEW=$(jq -nc --arg head "$HEX40_A" --arg base_oid "$HEX40_B" '{
  headRefOid: $head, baseRefName: "main", baseRefOid: $base_oid,
  commits: { totalCount: 1 },
  state: "CLOSED", isDraft: false,
  title: "t", author: { login: "alice" }, labels: [], changedFiles: 1
}')
export MOCK_GH_GRAPHQL='{"data":{"repository":{"pullRequest":{"headRefOid":"","reviews":{"nodes":[]},"comments":{"nodes":[]},"reviewThreads":{"nodes":[]}}}}}'

# Local mode (no CI) so bootstrap is skipped (script doesn't try to fetch)
result=$(run_hook "--repo owner/repo --pr 42")
decision=$(echo "$result" | jq -r '.decision // ""')
reason=$(echo "$result" | jq -r '.reason // ""')
assert_eq "closed → decision=block" "block" "$decision"
assert_contains "closed → reason mentions CLOSED" "CLOSED" "$reason"

# ============================================================================
# Test 2: draft PR without --include-drafts → block
# ============================================================================
printf "\n=== draft PR is blocked ===\n"
export MOCK_GH_PR_VIEW=$(jq -nc --arg head "$HEX40_A" --arg base_oid "$HEX40_B" '{
  headRefOid: $head, baseRefName: "main", baseRefOid: $base_oid,
  commits: { totalCount: 1 },
  state: "OPEN", isDraft: true,
  title: "t", author: { login: "alice" }, labels: [], changedFiles: 1
}')
result=$(run_hook "--repo owner/repo --pr 43")
decision=$(echo "$result" | jq -r '.decision // ""')
reason=$(echo "$result" | jq -r '.reason // ""')
assert_eq "draft → decision=block" "block" "$decision"
assert_contains "draft → reason mentions draft" "draft" "$reason"

# ============================================================================
# Test 3: draft PR with --include-drafts → proceeds
# ============================================================================
printf "\n=== draft + --include-drafts proceeds ===\n"
result=$(run_hook "--repo owner/repo --pr 43 --include-drafts")
ctx=$(echo "$result" | jq -r '.hookSpecificOutput.additionalContext // ""')
assert_contains "draft override emits pr-draft tag" "<pr-draft>true</pr-draft>" "$ctx"
assert_contains "draft override emits state OPEN" "<pr-state>OPEN</pr-state>" "$ctx"
assert_contains "draft override emits head-sha" "<head-sha>${HEX40_A}</head-sha>" "$ctx"

# ============================================================================
# Test 4: bot self-review → block
# ============================================================================
printf "\n=== bot self-review blocked ===\n"
export MOCK_GH_PR_VIEW=$(jq -nc --arg head "$HEX40_A" --arg base_oid "$HEX40_B" '{
  headRefOid: $head, baseRefName: "main", baseRefOid: $base_oid,
  commits: { totalCount: 1 },
  state: "OPEN", isDraft: false,
  title: "t", author: { login: "human" }, labels: [], changedFiles: 1
}')
# Set bot login to match the local commit author, which is "T" from setup above
export MOCK_GH_USER_LOGIN="T"
# We need the worktree to point to a commit that's the bot's
( cd "$WORKTREE_DIR" \
  && git -c user.email=bot@bot -c user.name=T commit --allow-empty -q -m bot >/dev/null )
HEAD_HERE=$(git -C "$WORKTREE_DIR" rev-parse HEAD)
export MOCK_GH_PR_VIEW=$(jq -nc --arg head "$HEAD_HERE" --arg base_oid "$HEX40_B" '{
  headRefOid: $head, baseRefName: "main", baseRefOid: $base_oid,
  commits: { totalCount: 1 },
  state: "OPEN", isDraft: false,
  title: "t", author: { login: "human" }, labels: [], changedFiles: 1
}')
result=$(run_hook "--repo owner/repo --pr 44")
decision=$(echo "$result" | jq -r '.decision // ""')
reason=$(echo "$result" | jq -r '.reason // ""')
assert_eq "bot self-review → decision=block" "block" "$decision"
assert_contains "bot self-review → reason names user" "T" "$reason"

# ============================================================================
# Test 5: manual --latest-reviewed-commit override
# ============================================================================
printf "\n=== manual override propagates ===\n"
export MOCK_GH_USER_LOGIN="some-other-user"
( cd "$WORKTREE_DIR" \
  && git -c user.email=h@h -c user.name=Human commit --allow-empty -q -m human >/dev/null )
HEAD_HERE=$(git -C "$WORKTREE_DIR" rev-parse HEAD)
export MOCK_GH_PR_VIEW=$(jq -nc --arg head "$HEAD_HERE" --arg base_oid "$HEX40_B" '{
  headRefOid: $head, baseRefName: "main", baseRefOid: $base_oid,
  commits: { totalCount: 1 },
  state: "OPEN", isDraft: false,
  title: "t", author: { login: "human" }, labels: [], changedFiles: 1
}')
result=$(run_hook "--repo owner/repo --pr 45 --latest-reviewed-commit deadbeefcafe")
ctx=$(echo "$result" | jq -r '.hookSpecificOutput.additionalContext // ""')
assert_contains "manual lrc passed through" "<latest-reviewed-commit>deadbeefcafe</latest-reviewed-commit>" "$ctx"
assert_contains "manual source tag" "<latest-reviewed-source>manual</latest-reviewed-source>" "$ctx"

# ============================================================================
# Test 6: tags emitted (head-sha, base-branch, base-sha, pr-title, etc.)
# ============================================================================
printf "\n=== expanded tags emitted ===\n"
result=$(run_hook "--repo owner/repo --pr 46")
ctx=$(echo "$result" | jq -r '.hookSpecificOutput.additionalContext // ""')
assert_contains "emits repo" "<repo>owner/repo</repo>" "$ctx"
assert_contains "emits pr-number" "<pr-number>46</pr-number>" "$ctx"
assert_contains "emits head-sha" "<head-sha>${HEAD_HERE}</head-sha>" "$ctx"
assert_contains "emits base-branch" "<base-branch>main</base-branch>" "$ctx"
assert_contains "emits base-sha" "<base-sha>${HEX40_B}</base-sha>" "$ctx"
assert_contains "emits pr-title" "<pr-title>t</pr-title>" "$ctx"
assert_contains "emits pr-author" "<pr-author>human</pr-author>" "$ctx"
assert_contains "emits pr-state" "<pr-state>OPEN</pr-state>" "$ctx"
assert_contains "emits changed-files-count" "<changed-files-count>1</changed-files-count>" "$ctx"

# ============================================================================
# Test 7: --force-post emits force-post tag
# ============================================================================
printf "\n=== --force-post tag ===\n"
result=$(run_hook "--repo owner/repo --pr 46 --force-post")
ctx=$(echo "$result" | jq -r '.hookSpecificOutput.additionalContext // ""')
assert_contains "force-post tag emitted" "<force-post>true</force-post>" "$ctx"

# ============================================================================
# Test 8: --approval-level emits approval-level tag (valid values)
# ============================================================================
printf "\n=== --approval-level tag ===\n"
for level in all critical important; do
  result=$(run_hook "--repo owner/repo --pr 46 --approval-level $level")
  ctx=$(echo "$result" | jq -r '.hookSpecificOutput.additionalContext // ""')
  assert_contains "approval-level=$level emitted" "<approval-level>$level</approval-level>" "$ctx"
done

# Default (omitted) should not emit the tag
result=$(run_hook "--repo owner/repo --pr 46")
ctx=$(echo "$result" | jq -r '.hookSpecificOutput.additionalContext // ""')
if [[ "$ctx" == *"<approval-level>"* ]]; then
  fail "approval-level omitted by default" "tag should not be present\n      in: $ctx"
else
  pass "approval-level omitted by default"
fi

# ============================================================================
# Test 9: --approval-level rejects invalid value
# ============================================================================
printf "\n=== --approval-level invalid ===\n"
result=$(run_hook "--repo owner/repo --pr 46 --approval-level bogus")
decision=$(echo "$result" | jq -r '.decision // ""')
reason=$(echo "$result" | jq -r '.reason // ""')
assert_eq "bogus → decision=block" "block" "$decision"
assert_contains "bogus → reason names the option" "approval-level" "$reason"

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
