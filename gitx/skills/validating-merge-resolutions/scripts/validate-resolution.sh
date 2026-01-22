#!/bin/bash
# Validates merge/rebase conflict resolutions
# Usage: validate-resolution.sh [file_patterns...]
# Output: Markdown validation report
# Auto-detects project language if no patterns provided

set -uo pipefail

# Auto-detect project language(s) and return default patterns
detect_patterns() {
  local patterns=()

  # Python
  if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
    patterns+=("*.py")
  fi

  # TypeScript/JavaScript
  if [[ -f "tsconfig.json" ]] || [[ -f "package.json" ]]; then
    patterns+=("*.ts" "*.tsx" "*.js" "*.jsx")
  fi

  # Go
  if [[ -f "go.mod" ]]; then
    patterns+=("*.go")
  fi

  # Rust
  if [[ -f "Cargo.toml" ]]; then
    patterns+=("*.rs")
  fi

  # Always include config files
  patterns+=("*.json" "*.yaml" "*.yml")

  # Fallback: all common code files if only config patterns detected
  if [[ ${#patterns[@]} -le 3 ]]; then
    patterns=("*.py" "*.ts" "*.tsx" "*.js" "*.jsx" "*.go" "*.rs" "*.json" "*.yaml" "*.yml")
  fi

  echo "${patterns[@]}"
}

# Type checking - auto-detect and run appropriate checker
run_type_check() {
  # Python: mypy or pyright
  if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
    if command -v mypy &> /dev/null; then
      echo "Running mypy..." >&2
      mypy . 2>&1 | head -50 || true
      return 0
    elif command -v pyright &> /dev/null; then
      echo "Running pyright..." >&2
      pyright 2>&1 | head -50 || true
      return 0
    fi
  fi

  # TypeScript
  if [[ -f "tsconfig.json" ]]; then
    echo "Running tsc..." >&2
    npx tsc --noEmit 2>&1 | head -50 || true
    return 0
  fi

  # Go
  if [[ -f "go.mod" ]]; then
    echo "Running go vet..." >&2
    go vet ./... 2>&1 | head -50 || true
    return 0
  fi

  # Rust
  if [[ -f "Cargo.toml" ]]; then
    echo "Running cargo check..." >&2
    cargo check 2>&1 | head -50 || true
    return 0
  fi

  echo "SKIP"
  return 1
}

# Lint checking - auto-detect and run appropriate linter
run_lint_check() {
  # Python: ruff, flake8
  if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
    if command -v ruff &> /dev/null; then
      echo "Running ruff..." >&2
      ruff check . 2>&1 | head -50 || true
      return 0
    elif command -v flake8 &> /dev/null; then
      echo "Running flake8..." >&2
      flake8 . 2>&1 | head -50 || true
      return 0
    fi
  fi

  # JavaScript/TypeScript via package.json
  if [[ -f "package.json" ]] && grep -q '"lint"' package.json; then
    echo "Running npm lint..." >&2
    npm run lint 2>&1 | head -50 || true
    return 0
  fi

  # Go
  if [[ -f "go.mod" ]]; then
    if command -v golangci-lint &> /dev/null; then
      echo "Running golangci-lint..." >&2
      golangci-lint run 2>&1 | head -50 || true
      return 0
    fi
  fi

  # Rust
  if [[ -f "Cargo.toml" ]]; then
    echo "Running cargo clippy..." >&2
    cargo clippy 2>&1 | head -50 || true
    return 0
  fi

  echo "SKIP"
  return 1
}

# Get patterns: use provided args or auto-detect
if [[ $# -eq 0 ]]; then
  read -ra PATTERNS <<< "$(detect_patterns)"
else
  PATTERNS=("$@")
fi

# Build include patterns for grep
INCLUDE_ARGS=""
for pattern in "${PATTERNS[@]}"; do
  INCLUDE_ARGS="$INCLUDE_ARGS --include=$pattern"
done

# Track results
MARKERS_FOUND=false
MARKERS_COUNT=0
SYNTAX_VALID=true
SYNTAX_ERRORS=""
TYPES_VALID=true
TYPE_ERRORS=""
TYPES_SKIPPED=false
LINT_VALID=true
LINT_WARNINGS=""
LINT_SKIPPED=false

# Check 1: Conflict markers
echo "Checking for conflict markers..." >&2
MARKER_RESULTS=$(grep -rn $INCLUDE_ARGS -E "^(<<<<<<<|=======|>>>>>>>)" . 2>/dev/null || true)
if [[ -n "$MARKER_RESULTS" ]]; then
  MARKERS_FOUND=true
  MARKERS_COUNT=$(echo "$MARKER_RESULTS" | wc -l)
fi

# Check 2: JSON/YAML syntax validation
echo "Validating config file syntax..." >&2
for configfile in $(find . -maxdepth 3 \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) -type f 2>/dev/null | head -20); do
  if [[ "$configfile" == *.json ]]; then
    if ! jq . "$configfile" > /dev/null 2>&1; then
      SYNTAX_VALID=false
      SYNTAX_ERRORS="$SYNTAX_ERRORS$configfile: invalid JSON\n"
    fi
  else
    # YAML validation with yq if available
    if command -v yq &> /dev/null; then
      if ! yq . "$configfile" > /dev/null 2>&1; then
        SYNTAX_VALID=false
        SYNTAX_ERRORS="$SYNTAX_ERRORS$configfile: invalid YAML\n"
      fi
    fi
  fi
done

# Check 3: Type check (language-agnostic)
TYPE_OUTPUT=$(run_type_check)
if [[ "$TYPE_OUTPUT" == "SKIP" ]]; then
  TYPES_SKIPPED=true
elif echo "$TYPE_OUTPUT" | grep -qiE "error"; then
  TYPES_VALID=false
  TYPE_ERRORS=$(echo "$TYPE_OUTPUT" | grep -iE "error" | head -10)
fi

# Check 4: Lint check (language-agnostic)
LINT_OUTPUT=$(run_lint_check)
if [[ "$LINT_OUTPUT" == "SKIP" ]]; then
  LINT_SKIPPED=true
elif echo "$LINT_OUTPUT" | grep -qiE "error|warning"; then
  LINT_WARNINGS=$(echo "$LINT_OUTPUT" | grep -iE "error|warning" | head -10)
  if echo "$LINT_OUTPUT" | grep -qi "error"; then
    LINT_VALID=false
  fi
fi

# Determine overall status
if [[ "$MARKERS_FOUND" == "true" ]]; then
  OVERALL="DO_NOT_PROCEED"
  OVERALL_MSG="Conflict markers still present"
elif [[ "$SYNTAX_VALID" == "false" ]]; then
  OVERALL="DO_NOT_PROCEED"
  OVERALL_MSG="Syntax errors found"
elif [[ "$TYPES_VALID" == "false" ]]; then
  OVERALL="PROCEED_WITH_CAUTION"
  OVERALL_MSG="Type errors found"
elif [[ "$LINT_VALID" == "false" ]]; then
  OVERALL="PROCEED_WITH_CAUTION"
  OVERALL_MSG="Lint errors found"
else
  OVERALL="PROCEED"
  OVERALL_MSG="All checks passed"
fi

# Helper for status display
types_status() {
  if [[ "$TYPES_SKIPPED" == "true" ]]; then
    echo "SKIP"
  elif [[ "$TYPES_VALID" == "true" ]]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}

lint_status() {
  if [[ "$LINT_SKIPPED" == "true" ]]; then
    echo "SKIP"
  elif [[ "$LINT_VALID" == "true" ]]; then
    echo "PASS"
  else
    echo "WARN"
  fi
}

# Output as markdown report
cat << EOF
## Validation Report

| Check | Status | Details |
|-------|--------|---------|
| Conflict Markers | $(if [[ "$MARKERS_FOUND" == "true" ]]; then echo "FAIL"; else echo "PASS"; fi) | $MARKERS_COUNT remaining |
| Syntax Valid | $(if [[ "$SYNTAX_VALID" == "true" ]]; then echo "PASS"; else echo "FAIL"; fi) | $(if [[ -n "$SYNTAX_ERRORS" ]]; then echo "errors found"; else echo "OK"; fi) |
| Types Check | $(types_status) | $(if [[ "$TYPES_SKIPPED" == "true" ]]; then echo "no checker"; elif [[ -n "$TYPE_ERRORS" ]]; then echo "errors found"; else echo "OK"; fi) |
| Lint Check | $(lint_status) | $(if [[ "$LINT_SKIPPED" == "true" ]]; then echo "no linter"; elif [[ -n "$LINT_WARNINGS" ]]; then echo "warnings found"; else echo "OK"; fi) |

### Overall: $OVERALL

$OVERALL_MSG
EOF

# Exit with appropriate code
if [[ "$OVERALL" == "DO_NOT_PROCEED" ]]; then
  exit 1
elif [[ "$OVERALL" == "PROCEED_WITH_CAUTION" ]]; then
  exit 0
else
  exit 0
fi
