# Issue Script Interfaces

Complete specifications for issue management scripts.

## Common Patterns

### JSON Output Schema

All scripts producing JSON follow these conventions:

- Use lowercase field names
- ISO 8601 timestamps where applicable
- Null for missing optional fields
- Arrays for multi-value fields (labels, assignees)

### Error Output

On error (exit code 2), scripts output:

```json
{
  "error": "Error message",
  "details": "Additional context",
  "suggestion": "How to fix"
}
```

### Info Mode vs Execute Mode

Scripts with `--execute` flag:

1. **Info mode** (default): Preview action, output JSON, exit 0
2. **Execute mode**: Perform action, output result, exit 0 on success

## issue-create.sh

### Full Options

```bash
scripts/issue-create.sh [options]

Options:
  --title <text>          Issue title (required)
  --body <text>           Issue body (markdown)
  --template <name>       Template name from .github/ISSUE_TEMPLATE/
  --label <label>         Label (repeatable: --label bug --label urgent)
  --assignee <user>       Assignee (repeatable)
  --milestone <name>      Milestone name
  --project <name>        Project name or number
  --priority <level>      Add priority:level label
  --execute               Create the issue (default: preview only)
```

### Template Handling

If `--template` is provided:
1. Read template file
2. Extract frontmatter defaults (labels, assignees)
3. Merge with CLI options (CLI overrides template)
4. Use template body if no `--body` provided

### Exit Codes

- `0` - Success (info mode: ready to create, execute mode: created)
- `2` - Error (missing title, invalid template, gh CLI error)

### Output Examples

**Info mode**:
```json
{
  "title": "Add dark mode support",
  "body": "Users have requested...",
  "labels": ["enhancement", "priority:medium", "ui"],
  "assignees": ["alice"],
  "milestone": "v2.0",
  "project": "Frontend",
  "template_used": "feature_request"
}
```

**Execute mode**:
```json
{
  "number": 456,
  "url": "https://github.com/owner/repo/issues/456",
  "title": "Add dark mode support",
  "state": "open"
}
```

## issue-close.sh

### Full Options

```bash
scripts/issue-close.sh <issue> [options]

Arguments:
  <issue>                 Issue number or URL

Options:
  --reason <type>         completed (default) or not_planned
  --comment <text>        Add comment before closing
  --link-pr <number>      Link PR that resolves this issue
  --execute               Close the issue (default: preview only)
```

### Exit Codes

- `0` - Success (info mode: ready to close, execute mode: closed)
- `1` - Issue already closed (no action needed)
- `2` - Error (issue not found, invalid reason, gh CLI error)

### Output Examples

**Info mode (issue open)**:
```json
{
  "issue": "123",
  "current_state": "open",
  "reason": "completed",
  "comment": "Fixed in PR #456",
  "linked_pr": "456"
}
```

**Info mode (already closed)**:
```json
{
  "issue": "123",
  "current_state": "closed",
  "closed_at": "2025-01-15T10:30:00Z",
  "closed_by": "alice",
  "message": "Issue already closed"
}
```

**Execute mode**:
```json
{
  "issue": "123",
  "state": "closed",
  "reason": "completed",
  "url": "https://github.com/owner/repo/issues/123"
}
```

## issue-list.sh

### Full Options

```bash
scripts/issue-list.sh [options]

Options:
  --state <state>         open (default), closed, or all
  --label <label>         Filter by label (repeatable)
  --assignee <user>       Filter by assignee (@me for current user)
  --milestone <name>      Filter by milestone
  --priority <level>      Filter by priority:level label
  --limit <n>             Maximum results (default: 30, max: 100)
  --format <format>       json (default) or table
  --sort <field>          created, updated, comments (default: created)
  --direction <dir>       asc or desc (default: desc)
```

### Exit Codes

- `0` - Success (may return empty array if no matches)
- `2` - Error (invalid filter, gh CLI error)

### Output Examples

**JSON format**:
```json
[
  {
    "number": 123,
    "title": "Fix parser bug",
    "state": "open",
    "labels": ["bug", "priority:high"],
    "assignees": ["alice", "bob"],
    "milestone": "v1.0",
    "created_at": "2025-01-10T09:00:00Z",
    "updated_at": "2025-01-15T14:30:00Z",
    "comments": 5,
    "url": "https://github.com/owner/repo/issues/123"
  }
]
```

**Table format**:
```
#     State  Priority  Title                 Assignee  Milestone
123   open   high      Fix parser bug        alice     v1.0
124   open   medium    Add validation        bob       v1.1
```

## issue-update.sh

### Full Options

```bash
scripts/issue-update.sh <issue> [options]

Arguments:
  <issue>                 Issue number or URL

Options:
  --title <text>          Update title
  --body <text>           Update body
  --add-label <label>     Add label (repeatable)
  --remove-label <label>  Remove label (repeatable)
  --set-labels <labels>   Replace all labels (comma-separated)
  --milestone <name>      Set milestone (empty string to clear)
  --state <state>         open or closed
  --execute               Apply updates (default: preview only)
```

### Exit Codes

- `0` - Success (info mode: changes ready, execute mode: updated)
- `1` - No changes detected
- `2` - Error (issue not found, invalid field, gh CLI error)

### Output Examples

**Info mode (with changes)**:
```json
{
  "issue": "123",
  "changes": {
    "title": {
      "from": "Fix bug",
      "to": "Fix parser bug in nested expressions"
    },
    "labels": {
      "add": ["priority:high", "regression"],
      "remove": ["priority:medium"]
    },
    "milestone": {
      "from": "v1.0",
      "to": "v1.1"
    }
  }
}
```

**Info mode (no changes)**:
```json
{
  "issue": "123",
  "message": "No changes detected"
}
```

**Execute mode**:
```json
{
  "issue": "123",
  "updated": true,
  "url": "https://github.com/owner/repo/issues/123"
}
```

## issue-view.sh

### Full Options

```bash
scripts/issue-view.sh <issue> [options]

Arguments:
  <issue>                 Issue number or URL

Options:
  --format <format>       json or markdown (default: markdown)
  --comments              Include comments
  --events                Include timeline events
  --max-comments <n>      Maximum comments to include (default: 10)
```

### Exit Codes

- `0` - Success
- `2` - Error (issue not found, gh CLI error)

### Output Examples

**Markdown format (default)**:
```markdown
# Issue #123: Fix parser bug in nested expressions

**State**: open
**Created**: 2025-01-10 by alice
**Updated**: 2025-01-15
**Labels**: bug, priority:high, regression
**Assignees**: alice, bob
**Milestone**: v1.1

## Description

Parser fails when encountering nested expressions like:
...

## Comments (5)

### alice commented on Jan 10, 2025

I can reproduce this with the following test case...

### bob commented on Jan 11, 2025

Looks like the issue is in the tokenizer...
```

**JSON format**:
```json
{
  "number": 123,
  "title": "Fix parser bug in nested expressions",
  "state": "open",
  "created_at": "2025-01-10T09:00:00Z",
  "updated_at": "2025-01-15T14:30:00Z",
  "author": "alice",
  "labels": ["bug", "priority:high", "regression"],
  "assignees": ["alice", "bob"],
  "milestone": "v1.1",
  "body": "Parser fails when encountering...",
  "comments": [
    {
      "author": "alice",
      "created_at": "2025-01-10T10:00:00Z",
      "body": "I can reproduce this..."
    }
  ],
  "events": [
    {
      "event": "labeled",
      "actor": "alice",
      "created_at": "2025-01-10T09:05:00Z",
      "label": "priority:high"
    }
  ]
}
```

## Implementation Notes

### gh CLI Integration

All scripts wrap `gh issue` commands:

- `issue-create.sh` → `gh issue create`
- `issue-close.sh` → `gh issue close`
- `issue-list.sh` → `gh issue list`
- `issue-update.sh` → `gh issue edit`
- `issue-view.sh` → `gh issue view`

### Validation Strategy

Before calling gh CLI:

1. **Check gh availability**: `gh --version`
2. **Verify repo context**: `gh repo view --json nameWithOwner`
3. **Validate issue exists**: `gh issue view <issue> --json state`
4. **Verify references exist**: Check labels, milestones, projects via `gh api`

### Error Recovery

Common error scenarios:

| Error | Detection | Suggestion |
|-------|-----------|------------|
| gh CLI not found | Command not found | Install gh CLI |
| Not in repo | gh error: not a git repository | Run from repo directory |
| Issue not found | gh error: Could not resolve | Check issue number |
| Invalid label | API 422 error | List available labels |
| Milestone not found | API 404 error | List available milestones |

For each error, provide actionable suggestion in output.
