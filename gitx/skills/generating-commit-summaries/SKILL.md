---

name: gitx:generating-commit-summaries
description: >-
  Generates narrative commit summaries with bullet-point details. Use when
  creating PR descriptions, issue comments, or review responses that need
  commit context.
version: 1.0.0
allowed-tools: Bash(git:*), AskUserQuestion
model: sonnet
---

# Generating Commit Summaries

Generate structured summaries from git commit history.

## Input Modes

### Multi-Commit Summary (`-c <commit>` or `--commit <commit>`)

1. Validate commit hash: `git rev-parse --verify <commit>^{commit}`
2. Get commits since: `git log --oneline <commit>..HEAD`
3. Get changed files: `git diff --stat <commit>..HEAD`

### Single-Commit Summary (`-sc <commit>` or `--single-commit <commit>`)

1. Validate commit hash: `git rev-parse --verify <commit>^{commit}`
2. Get commit details: `git show --stat --format="%s%n%n%b" <commit>`
3. Get commit diff: `git show --no-stat <commit>`

## Output Format

Generate "Both combined" format:

1. **Narrative summary**: A cohesive paragraph summarizing all changes holistically
2. **Commit list**: Bullet points of each commit for reference

```markdown
[Narrative paragraph explaining the changes and their purpose]

### Commits
- <commit-hash> <commit-message>
- <commit-hash> <commit-message>
```

## Preview Confirmation

Use AskUserQuestion:

- Show preview: Full generated summary
- Question: "Post this commit summary to [target] #\<number\>?"
- Header: "Confirm"
- Options:
  1. "Post this summary" - Proceed to validation
  2. "Cancel" - Abort posting

## Error Handling

| Error | Message |
|-------|---------|
| Invalid commit | "Commit '\<hash\>' not found in repository. Please verify the commit hash." |
| Not in history | "Commit '\<hash\>' exists but is not in current branch's history." |

## Output

Store generated summary in `$comment` variable for validation.
