---
name: gitx:posting-github-comments
description: >-
  Scripts for posting comments to GitHub PRs and issues with target inference.
  Invoked when commenting on PRs or issues.
allowed-tools: Bash(scripts/comment-post.sh:*)
model: sonnet
---

# Posting GitHub Comments

Post comments to PRs/issues with smart target inference from current branch.

## Scripts

### comment-post.sh

Posts comments or gathers commit info for summaries.

```bash
scripts/comment-post.sh <type> [number] [options]
```

**Type**: `pr` or `issue`

**Options**: `--body <text>`, `--infer`, `--get-commits`, `--since <sha>`

**Exit codes**: 0 success, 1 needs input, 2 error

## Target Inference

- **PR**: Uses `gh pr view` on current branch
- **Issue**: Extracts number from branch name patterns (e.g., `issue-123/...`)

## Hybrid Operation

Script handles inference and posting; LLM handles commit summarization and response extraction.
