---
name: gitx:merging-prs
description: >-
  Merges a PR and handles post-merge cleanup including issue closure and
  branch deletion. Use for finalizing approved pull requests with minimal
  LLM involvement.
allowed-tools: Bash(scripts/merge-pr.sh:*), Read
model: sonnet
---

## Input prompt arguments

Leave input prompt unchanged. I'll be referencing it later as `$input_prompt`.

## Execution

Run the script with the input prompt arguments as-is.

```bash
scripts/merge-pr.sh $input_prompt
```

## Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Report: PR #{pr} merged via {strategy}. Closed issues: {closed_issues}. Branch deleted: {branch_deleted} |
| 1 | Pre-flight failed | Present {check} failure: "{message}". Ask user whether to proceed anyway |
| 2 | Error | Report {error}: "{message}". Suggest manual fix |

## Examples

```bash
# Basic squash merge (current branch's PR)
scripts/merge-pr.sh --squash

# Merge with cleanup
scripts/merge-pr.sh 123 --squash -d
```

See [references/extra-examples.md](references/extra-examples.md) for more scenarios.

## Issue Closing Handling

The script automatically:

1. Parses PR description for `Closes #123`, `Fixes #456`, `Resolves #789`
2. Waits briefly for GitHub's auto-close to process
3. Manually closes any issues that didn't auto-close
4. Reports all closed issues in output

## Pre-flight Check Failure Handling

Callers should handle pre-flight failures by asking the user whether to proceed anyway.
