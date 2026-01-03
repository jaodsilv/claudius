---
description: Gets next issue by priority when selecting work. Use for picking the highest priority available task.
argument-hint: "[-d detailed]"
allowed-tools: Bash(gh issue:*), AskUserQuestion
---

# Next Issue

Find the next issue to work on based on priority labels.

## Parse Arguments

From $ARGUMENTS, extract:
- `-d` or `--include-description`: Include full issue details

## Priority Order

Search for open issues in this priority order:

1. `priority:critical`
2. `priority:high`
3. `priority:medium`
4. `priority:low`
5. No priority label (lowest)

**Note**: These label names follow a common GitHub convention. If your repository
uses different labels (e.g., `P0`, `P1`, `critical`, `high`), modify the search
queries below accordingly.

## Search for Issues

Search issues in priority order until one is found:

```bash
# Critical priority
gh issue list --label "priority:critical" --state open --limit 1 --json number,title,labels,assignees

# If none found, try high
gh issue list --label "priority:high" --state open --limit 1 --json number,title,labels,assignees

# If none found, try medium
gh issue list --label "priority:medium" --state open --limit 1 --json number,title,labels,assignees

# If none found, try low
gh issue list --label "priority:low" --state open --limit 1 --json number,title,labels,assignees

# If none found, get any open issue without priority
gh issue list --state open --limit 5 --json number,title,labels,assignees
```

## Handle Multiple Same-Priority Issues

If multiple issues have the same priority:

Use AskUserQuestion:
- "Found multiple <priority> priority issues. Which one should be worked on?"
- Show list with numbers and titles
- Options: List each issue, plus "Show me more options"

## Output Format

### Basic mode (no -d flag)

Just output the issue number:

```text
#123
```

### Detailed mode (-d flag)

Fetch full details:
- `gh issue view <number> --json number,title,body,labels,assignees,milestone,state`

Output formatted details:

```text
Issue #123: <title>
Priority: <priority-label>
Assignees: <assignees or "unassigned">
Milestone: <milestone or "none">
Labels: <other labels>

Description:
<first 500 chars of body>
```

## Suggest Next Steps

After showing the issue:

```text
To start working on this issue:
  /gitx:fix-issue 123

Or create a worktree manually:
  /gitx:worktree 123
```

## Error Handling

1. No open issues found: Report "No open issues found in this repository".
2. gh CLI not authenticated: Report authentication needed.
3. No priority labels in repo: Suggest creating priority labels or show all open issues.
