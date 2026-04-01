#!/bin/bash
# Tests for scripts/issues/parse-references.sh
# Run: bash tests/parse-references.test.sh

set -uo pipefail

# ---------------------------------------------------------------------------
# Test framework
# ---------------------------------------------------------------------------
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=()

pass() {
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  printf "  PASS: %s\n" "$1"
}

fail() {
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  FAILURES+=("$1: $2")
  printf "  FAIL: %s -- %s\n" "$1" "$2"
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$desc"
  else
    fail "$desc" "expected '$expected', got '$actual'"
  fi
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARSE_SCRIPT="$REPO_ROOT/gitx/scripts/issues/parse-references.sh"

# Ensure HOOK_PLUGIN_NAME is set for logging lib
export HOOK_PLUGIN_NAME="GITX"

# ---------------------------------------------------------------------------
# Test: Bare number
# ---------------------------------------------------------------------------
printf "\n=== Bare number ===\n"

result=$(bash "$PARSE_SCRIPT" "123")
assert_eq "bare number parses" '{"issue_number":123,"source_type":"bare"}' "$result"

result=$(bash "$PARSE_SCRIPT" "1")
assert_eq "bare single digit" '{"issue_number":1,"source_type":"bare"}' "$result"

# ---------------------------------------------------------------------------
# Test: Hash prefix
# ---------------------------------------------------------------------------
printf "\n=== Hash prefix ===\n"

result=$(bash "$PARSE_SCRIPT" "#456")
assert_eq "hash prefix parses" '{"issue_number":456,"source_type":"hash"}' "$result"

# ---------------------------------------------------------------------------
# Test: Issue prefix
# ---------------------------------------------------------------------------
printf "\n=== Issue prefix ===\n"

result=$(bash "$PARSE_SCRIPT" "issue-789")
assert_eq "issue prefix parses" '{"issue_number":789,"source_type":"prefix"}' "$result"

# ---------------------------------------------------------------------------
# Test: GitHub URL
# ---------------------------------------------------------------------------
printf "\n=== GitHub URL ===\n"

result=$(bash "$PARSE_SCRIPT" "https://github.com/owner/repo/issues/42")
assert_eq "github url parses" '{"issue_number":42,"source_type":"url"}' "$result"

result=$(bash "$PARSE_SCRIPT" "http://github.com/owner/repo/issues/99")
assert_eq "http url parses" '{"issue_number":99,"source_type":"url"}' "$result"

# ---------------------------------------------------------------------------
# Test: Branch name
# ---------------------------------------------------------------------------
printf "\n=== Branch name ===\n"

result=$(bash "$PARSE_SCRIPT" "feature/issue-42-add-auth")
assert_eq "branch name parses" '{"issue_number":42,"source_type":"branch"}' "$result"

result=$(bash "$PARSE_SCRIPT" "bugfix/issue-100-fix")
assert_eq "bugfix branch parses" '{"issue_number":100,"source_type":"branch"}' "$result"

# ---------------------------------------------------------------------------
# Test: Error cases
# ---------------------------------------------------------------------------
printf "\n=== Error cases ===\n"

result=$(bash "$PARSE_SCRIPT" "" 2>/dev/null)
assert_eq "empty input" '{"issue_number":null,"source_type":"unknown","error":"No issue reference provided"}' "$result"

result=$(bash "$PARSE_SCRIPT" "not-an-issue" 2>/dev/null)
assert_eq "no match" '{"issue_number":null,"source_type":"unknown","error":"Could not parse issue reference from: not-an-issue"}' "$result"

result=$(bash "$PARSE_SCRIPT" "#abc" 2>/dev/null)
assert_eq "invalid hash" '{"issue_number":null,"source_type":"unknown","error":"Could not parse issue reference from: #abc"}' "$result"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf "\n===================================\n"
printf "Tests: %d | Passed: %d | Failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
if [[ $TESTS_FAILED -gt 0 ]]; then
  printf "\nFailures:\n"
  for f in "${FAILURES[@]}"; do
    printf "  - %s\n" "$f"
  done
  printf "===================================\n"
  exit 1
else
  printf "All tests passed.\n"
  printf "===================================\n"
  exit 0
fi
