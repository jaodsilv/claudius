---
name: gitx:managing-issues
description: >-
  Manages GitHub issues with validation and two-phase execution.
  Invoked when creating, closing, listing, updating, or viewing issues.
allowed-tools: Bash(scripts/issue-create.sh:*), Bash(scripts/issue-close.sh:*), Bash(scripts/issue-list.sh:*), Bash(scripts/issue-update.sh:*), Bash(scripts/issue-view.sh:*)
model: sonnet
---

# Managing Issues

GitHub issue management operations with validation, template handling, and error recovery.

## Scripts

### issue-create.sh

Create issues with template selection and field validation.

```bash
scripts/issue-create.sh [options]
```

**Options**:
- `--title <text>` - Issue title (required)
- `--body <text>` - Issue body
- `--template <name>` - Template name
- `--label <label>` - Labels (repeatable)
- `--assignee <user>` - Assignees (repeatable)
- `--milestone <name>` - Milestone
- `--project <name>` - Project
- `--execute` - Create the issue

**Exit codes**: 0 ready, 2 error

**Output** (info mode):
```json
{
  "title": "Fix bug in parser",
  "body": "Description...",
  "labels": ["bug", "priority:high"],
  "template_used": "bug_report"
}
```

### issue-close.sh

Close issues with optional PR linking and status comment.

```bash
scripts/issue-close.sh <issue> [options]
```

**Options**:
- `--reason <completed|not_planned>` - Closure reason
- `--comment <text>` - Closing comment
- `--link-pr <number>` - Link PR number
- `--execute` - Close the issue

**Exit codes**: 0 ready, 1 already closed, 2 error

**Output** (info mode):
```json
{
  "issue": "123",
  "current_state": "open",
  "reason": "completed",
  "linked_pr": "456"
}
```

### issue-list.sh

List and filter issues with JSON output for processing.

```bash
scripts/issue-list.sh [options]
```

**Options**:
- `--state <open|closed|all>` - Filter by state (default: open)
- `--label <label>` - Filter by label (repeatable)
- `--assignee <user>` - Filter by assignee
- `--milestone <name>` - Filter by milestone
- `--priority <level>` - Filter by priority label
- `--limit <n>` - Maximum results (default: 30)
- `--format <json|table>` - Output format (default: json)

**Exit codes**: 0 success, 2 error

**Output** (json format):
```json
[
  {
    "number": 123,
    "title": "Fix parser bug",
    "state": "open",
    "labels": ["bug", "priority:high"],
    "assignee": "user",
    "milestone": "v1.0"
  }
]
```

### issue-update.sh

Update issue fields with validation and change preview.

```bash
scripts/issue-update.sh <issue> [options]
```

**Options**:
- `--title <text>` - Update title
- `--body <text>` - Update body
- `--add-label <label>` - Add label (repeatable)
- `--remove-label <label>` - Remove label (repeatable)
- `--milestone <name>` - Set milestone
- `--state <open|closed>` - Update state
- `--execute` - Apply updates

**Exit codes**: 0 ready, 1 no changes, 2 error

**Output** (info mode):
```json
{
  "issue": "123",
  "changes": {
    "labels": {
      "add": ["priority:high"],
      "remove": ["priority:medium"]
    },
    "milestone": {
      "from": "v1.0",
      "to": "v1.1"
    }
  }
}
```

### issue-view.sh

View issue details with formatted output.

```bash
scripts/issue-view.sh <issue> [options]
```

**Options**:

- `--json [fields]` - JSON output with comma-separated fields (default: full set)
- `--jq <expression>` - jq filter passed to gh CLI (requires --json or --use-case)
- `--use-case <name>` - Preset field selection (implies --json)
- `--comments` - Include comments (markdown mode only)
- `--events` - Include timeline events (markdown mode only)

**Use-cases**:

| Name | Fields | Notes |
|------|--------|-------|
| `branch-naming` | closedAt,labels,number,state,stateReason,title | Exit 1 if closed |
| `analysis` | author,body,closedAt,comments,createdAt,labels,milestone,title,updatedAt | Deep analysis |
| `picking` | assignees,labels,milestone,number,state,title | Issue triage |
| `pr-linking` | number,title | Minimal for PR refs |
| `quick` | number,state,title,url | Fast status |

**Exit codes**: 0 success, 1 closed (branch-naming only), 2 error

**Examples**:

```bash
# Markdown output (default)
scripts/issue-view.sh 123

# JSON with default fields
scripts/issue-view.sh 123 --json

# JSON with specific fields
scripts/issue-view.sh 123 --json number,title,labels

# Use preset for branch naming
scripts/issue-view.sh 123 --use-case branch-naming

# Filter with jq
scripts/issue-view.sh 123 --json --jq '.title'
scripts/issue-view.sh 123 --use-case quick --jq '.state'
```

## Two-Phase Pattern

Scripts use info mode by default (preview changes, output JSON), then `--execute` to perform the action.

Exceptions:

- `issue-list.sh` - Read-only, no execute flag
- `issue-view.sh` - Read-only, no execute flag

## Error Handling

All scripts validate inputs before execution:

1. Check gh CLI availability
2. Validate repository context
3. Verify issue exists (for update/close/view)
4. Validate field values (labels, milestones exist)
5. Return actionable error messages with exit code 2

## Transparent Invocation

Callers describe WHAT operation is needed. Scripts handle HOW to interact with gh CLI.

**Good**: "Create an issue with title 'Fix bug' and label 'priority:high'"
**Bad**: "Run gh issue create --title 'Fix bug' --label 'priority:high'"

## Additional Resources

### Reference Files

- **`references/script-interfaces.md`** - Complete script specifications with all options and JSON schemas
