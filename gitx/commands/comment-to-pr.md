---
description: Comments on a pull request when sharing status or responding. Use for PR discussion or posting summaries.
argument-hint: '[[--pr] <pr> | [--worktree] <worktree>] [[--comment] <comment> | -l or --last | -sc or --since-commit <hash> | (-c or --single-commit) <hash>] [-r or --review | -rr or --review-response [[--text] <text>]] [-f or --force]'
allowed-tools: Bash(gh pr *), Bash(git branch *), AskUserQuestion, Agent(gitx:comment-handler:comment-handler *), Skill(gitx:validating-comments *)
model: sonnet
---

# Comment on Pull Request

Add a comment to a GitHub pull request. Delegates complex flows to gitx:comment-handler:comment-handler.

## Step 0: Hook Additional Context Parsing

Parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`

Strip the `--worktree` argument from $ARGUMENTS if present.

## Parse Arguments

Extract from $ARGUMENTS:

- **PR number** or **Worktree** (optional): First positional argument, either a number or a worktree path
- **Comment text** (optional): Text after PR number or worktree path (unless flags used)
- **Named arguments**: See `Named Arguments Reference` section

## Named Arguments Reference

| Flag | Description |
|------|-------------|
| `-l`, `--last` | Post last Claude response from session |
| `-sc <hash>`, `--since-commit <hash>` | Summary of commits since hash (inclusive) |
| `-c <hash>`, `--single-commit <hash>` | Summary of single commit |
| `-r`, `--review` | Post the comment as a review |
| `-rr ["text"]`, `--review-response ["text"]` | Respond to review (auto-fetch or specified by "text") |
| `--force`, `-f` | IGNORE THIS FLAG. It is not used. |

**Combinations**:

- `-r` can combine with `-l` after a review agent result. Cannot combine `-r` with `-c` or `-sc` or `-rr`.
- `-rr` can combine with `-c` or `-sc` for commit evidence. Cannot combine `-rr` with `-l` or `-r`.

## Infer PR Number

If no PR number in arguments:

1. Get current branch: !`git branch --show-current`
2. Find PR: `gh pr view --json number,title`
3. If found: "Using PR #<number>: <title>"
4. If not found: List recent PRs via AskUserQuestion

## Flow Routing

### Simple: Inline Comment

If comment text provided directly in arguments:

1. Use skill `gitx:validating-comments`
2. Post: `gh pr comment <number> --body "$comment"` or, if -r is present, `gh pr review <number> --body "$comment"`
3. Report success

### Complex: Delegate to Agent

For flag-based flows, delegate to `gitx:comment-handler:comment-handler` with:

| Flag | flow_type | Required Data |
|------|-----------|---------------|
| `--last` | `last_response` | Caller extracts & provides `<latest responses>` |
| `-c`/`-sc` | `commit_summary` | `mode: multi\|single`, `commit: <hash>` |
| `-rr` | `review_response` | `review_text`, optional `commit`/`commit_mode` |
| `-r` | `review_posting` | `target_subtype: review`, optional `review_text` |

Common parameters: `target: <PR number>`, `target_type: pr`, `target_subtype: comment` (except review_posting).

Note: For `--last`, the main agent MUST extract responses from conversation - the agent cannot access history.

### Interactive: Template Selection

If no arguments or flags, use AskUserQuestion:

- Options: ["Summarize recent changes", "Request review", "Status update", "Post last response"]
- Route based on selection (delegate to agent for complex flows)

## Error Handling

| Error | Action |
|-------|--------|
| PR not found | Report and suggest checking number |
| Empty comment | Return to get comment text |
| gh not authenticated | Guide to `gh auth login` |
| Invalid flag combination | Report conflict |
| Agent failure | Report error from agent |
