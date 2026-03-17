#!/bin/bash
# Tests for scripts/lib/hook-output.sh
# Run: bash tests/hook-output.test.sh

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

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$desc"
  else
    fail "$desc" "expected to contain '$needle' in: $haystack"
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    pass "$desc"
  else
    fail "$desc" "expected NOT to contain '$needle' in: $haystack"
  fi
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Create a mock count-tokens.py that returns a controllable token count
# The mock reads from MOCK_TOKEN_COUNT env var
MOCK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hook-test-XXXXXX")
cat > "$MOCK_DIR/count-tokens.py" << 'MOCK_EOF'
#!/usr/bin/env python3
import os, sys, argparse
parser = argparse.ArgumentParser()
source = parser.add_mutually_exclusive_group(required=True)
source.add_argument("--filepath")
source.add_argument("--stdin", action="store_true")
parser.add_argument("--force-content-type", default=None)
parser.add_argument("--porcelain", action="store_true")
parser.add_argument("--base", default=None)
parser.add_argument("--model", default="sonnet")
args = parser.parse_args()
if args.stdin:
    sys.stdin.read()  # consume stdin
count = os.environ.get("MOCK_TOKEN_COUNT", "0")
if args.porcelain:
    print(count)
else:
    print(f"Tokens: {count}")
MOCK_EOF
chmod +x "$MOCK_DIR/count-tokens.py"

# Source hook-output.sh but override BASH_SOURCE[0] resolution
# by temporarily symlinking into our mock dir
cp "$LIB_DIR/hook-output.sh" "$MOCK_DIR/hook-output.sh"

# Source the library from the mock dir so it finds mock count-tokens.py
source "$MOCK_DIR/hook-output.sh"

# Create a test fixture file
echo "test content for injection" > "$FIXTURES_DIR/small.txt"

cleanup() {
  rm -rf "$MOCK_DIR"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Test: _escape_json
# ---------------------------------------------------------------------------
printf "\n=== _escape_json ===\n"

result=$(_escape_json 'hello "world"')
assert_eq "escapes double quotes" 'hello \"world\"' "$result"

result=$(_escape_json 'back\slash')
assert_eq "escapes backslashes" 'back\\slash' "$result"

result=$(_escape_json $'line1\nline2')
assert_eq "replaces newlines with spaces" 'line1 line2' "$result"

cr_input=$(printf 'cr\rreturn')
result=$(_escape_json "$cr_input")
assert_eq "replaces carriage returns with spaces" 'cr return' "$result"

result=$(_escape_json 'simple text')
assert_eq "passes through simple text" 'simple text' "$result"

result=$(_escape_json '')
assert_eq "handles empty string" '' "$result"

# ---------------------------------------------------------------------------
# Test: hook_output_context
# ---------------------------------------------------------------------------
printf "\n=== hook_output_context ===\n"

HOOK_EVENT_TYPE="PreToolUse"
result=$(hook_output_context "test context")
assert_contains "PreToolUse context has hookEventName" '"hookEventName": "PreToolUse"' "$result"
assert_contains "PreToolUse context has additionalContext" '"additionalContext": "test context"' "$result"

HOOK_EVENT_TYPE="UserPromptSubmit"
result=$(hook_output_context "prompt context")
assert_contains "UserPromptSubmit context has hookEventName" '"hookEventName": "UserPromptSubmit"' "$result"

unset HOOK_EVENT_TYPE
result=$(hook_output_context "default context")
assert_contains "default event type is UserPromptSubmit" '"hookEventName": "UserPromptSubmit"' "$result"

# ---------------------------------------------------------------------------
# Test: hook_output_block
# ---------------------------------------------------------------------------
printf "\n=== hook_output_block ===\n"

HOOK_EVENT_TYPE="PreToolUse"
result=$(hook_output_block "blocked reason")
assert_contains "PreToolUse block has deny decision" '"permissionDecision": "deny"' "$result"
assert_contains "PreToolUse block has reason" '"permissionDecisionReason": "blocked reason"' "$result"

HOOK_EVENT_TYPE="PostToolUse"
result=$(hook_output_block "post block")
assert_contains "PostToolUse block has block decision" '"decision": "block"' "$result"

HOOK_EVENT_TYPE="Stop"
result=$(hook_output_block "stop reason")
assert_contains "Stop block has block decision" '"decision": "block"' "$result"

HOOK_EVENT_TYPE="UserPromptSubmit"
result=$(hook_output_block "prompt block")
assert_contains "UserPromptSubmit block has block decision" '"decision": "block"' "$result"

# ---------------------------------------------------------------------------
# Test: Named constants
# ---------------------------------------------------------------------------
printf "\n=== Named constants ===\n"

assert_eq "OPUS_INJECT_CEILING" "4000" "$OPUS_INJECT_CEILING"
assert_eq "SONNET_INJECT_CEILING" "6000" "$SONNET_INJECT_CEILING"
assert_eq "HAIKU_INJECT_CEILING" "8000" "$HAIKU_INJECT_CEILING"
assert_eq "TARGETED_READ_CEILING" "20000" "$TARGETED_READ_CEILING"
assert_eq "SPLIT_TASK_CEILING" "40000" "$SPLIT_TASK_CEILING"

# ---------------------------------------------------------------------------
# Test: inject_or_read — per-model boundaries
# ---------------------------------------------------------------------------
printf "\n=== inject_or_read: Opus boundaries ===\n"

export MOCK_TOKEN_COUNT=3999
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "opus")
assert_contains "opus 3999 → inject" "<test-tag>" "$result"
assert_not_contains "opus 3999 → no strategy attr" 'strategy=' "$result"

export MOCK_TOKEN_COUNT=4000
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "opus")
assert_contains "opus 4000 → explicit-read" 'strategy="explicit-read"' "$result"

printf "\n=== inject_or_read: Sonnet boundaries ===\n"

export MOCK_TOKEN_COUNT=5999
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "sonnet")
assert_contains "sonnet 5999 → inject" "<test-tag>" "$result"
assert_not_contains "sonnet 5999 → no strategy attr" 'strategy=' "$result"

export MOCK_TOKEN_COUNT=6000
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "sonnet")
assert_contains "sonnet 6000 → explicit-read" 'strategy="explicit-read"' "$result"

printf "\n=== inject_or_read: Haiku boundaries ===\n"

export MOCK_TOKEN_COUNT=7999
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "haiku")
assert_contains "haiku 7999 → inject" "<test-tag>" "$result"
assert_not_contains "haiku 7999 → no strategy attr" 'strategy=' "$result"

export MOCK_TOKEN_COUNT=8000
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "haiku")
assert_contains "haiku 8000 → explicit-read" 'strategy="explicit-read"' "$result"

# ---------------------------------------------------------------------------
# Test: inject_or_read — targeted-read and split-task boundaries
# ---------------------------------------------------------------------------
printf "\n=== inject_or_read: targeted-read / split-task ===\n"

export MOCK_TOKEN_COUNT=19999
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "opus")
assert_contains "19999 → explicit-read" 'strategy="explicit-read"' "$result"

export MOCK_TOKEN_COUNT=20000
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "opus")
assert_contains "20000 → targeted-read" 'strategy="targeted-read"' "$result"
assert_contains "targeted-read mentions offset/limit" "offset and limit" "$result"

export MOCK_TOKEN_COUNT=39999
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "sonnet")
assert_contains "39999 → targeted-read" 'strategy="targeted-read"' "$result"

export MOCK_TOKEN_COUNT=40000
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag" "sonnet")
assert_contains "40000 → split-task" 'strategy="split-task"' "$result"
assert_contains "split-task mentions splitting" "splitting into smaller tasks" "$result"

# ---------------------------------------------------------------------------
# Test: inject_or_read — backward compatibility (2-arg call defaults to sonnet)
# ---------------------------------------------------------------------------
printf "\n=== inject_or_read: backward compat ===\n"

export MOCK_TOKEN_COUNT=5999
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag")
assert_contains "2-arg 5999 → inject (sonnet default)" "<test-tag>" "$result"
assert_not_contains "2-arg 5999 → no strategy attr" 'strategy=' "$result"

export MOCK_TOKEN_COUNT=6000
result=$(inject_or_read "$FIXTURES_DIR/small.txt" "test-tag")
assert_contains "2-arg 6000 → explicit-read (sonnet default)" 'strategy="explicit-read"' "$result"

# ---------------------------------------------------------------------------
# Test: inject_or_read_content — with known string sizes
# ---------------------------------------------------------------------------
printf "\n=== inject_or_read_content ===\n"

export MOCK_TOKEN_COUNT=100
result=$(inject_or_read_content "small diff content" "diff-tag" "sonnet" "code")
assert_contains "content inject wraps in tags" "<diff-tag>" "$result"
assert_contains "content inject includes content" "small diff content" "$result"

export MOCK_TOKEN_COUNT=7000
result=$(inject_or_read_content "medium diff content" "diff-tag" "sonnet" "code")
assert_contains "content explicit-read has strategy" 'strategy="explicit-read"' "$result"
assert_contains "content explicit-read points to tmpfile" "/hook-content-" "$result"

export MOCK_TOKEN_COUNT=25000
result=$(inject_or_read_content "large diff content" "diff-tag" "opus" "code")
assert_contains "content targeted-read has strategy" 'strategy="targeted-read"' "$result"

export MOCK_TOKEN_COUNT=50000
result=$(inject_or_read_content "huge diff content" "diff-tag" "haiku" "code")
assert_contains "content split-task has strategy" 'strategy="split-task"' "$result"

# Test content type parameter
export MOCK_TOKEN_COUNT=100
result=$(inject_or_read_content "prose text" "prose-tag" "sonnet" "prose")
assert_contains "content with prose type injects" "<prose-tag>" "$result"

# Test 2-arg backward compat defaults to sonnet
export MOCK_TOKEN_COUNT=5999
result=$(inject_or_read_content "compat content" "compat-tag")
assert_contains "content 2-arg defaults inject" "<compat-tag>" "$result"

export MOCK_TOKEN_COUNT=6000
result=$(inject_or_read_content "compat content" "compat-tag")
assert_contains "content 2-arg defaults explicit-read" 'strategy="explicit-read"' "$result"

# ---------------------------------------------------------------------------
# Test: inject_or_read_content — temp file persistence
# ---------------------------------------------------------------------------
printf "\n=== inject_or_read_content: temp file ===\n"

export MOCK_TOKEN_COUNT=7000
result=$(inject_or_read_content "persist test" "persist-tag" "sonnet" "code")
# Extract tmpfile path from result
tmpfile_path=$(echo "$result" | grep -oP '/[^ ]*hook-content-[^ ]*\.txt')
if [[ -n "$tmpfile_path" && -f "$tmpfile_path" ]]; then
  tmpfile_content=$(cat "$tmpfile_path")
  assert_eq "temp file contains content" "persist test" "$tmpfile_content"
  rm -f "$tmpfile_path"
else
  fail "temp file exists after function returns" "tmpfile not found at: $tmpfile_path"
fi

# ---------------------------------------------------------------------------
# Test: Fallback when count-tokens.py is missing
# ---------------------------------------------------------------------------
printf "\n=== Fallback: missing count-tokens.py ===\n"

# Temporarily rename mock script
mv "$MOCK_DIR/count-tokens.py" "$MOCK_DIR/count-tokens.py.bak"

result=$(inject_or_read "$FIXTURES_DIR/small.txt" "fallback-tag" "sonnet")
assert_contains "missing script → inject fallback" "<fallback-tag>" "$result"
assert_contains "fallback includes file content" "test content for injection" "$result"

result=$(inject_or_read_content "fallback content" "fallback-content-tag" "sonnet" "code")
assert_contains "missing script → content inject fallback" "<fallback-content-tag>" "$result"
assert_contains "content fallback includes content" "fallback content" "$result"

# Restore mock script
mv "$MOCK_DIR/count-tokens.py.bak" "$MOCK_DIR/count-tokens.py"

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
