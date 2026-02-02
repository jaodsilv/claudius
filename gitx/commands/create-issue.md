---

description: Create a GitHub issue from informal description
argument-hint: "<description> [-l labels] [-a assignee] [-t template] [-m milestone] [--no-preview]"
allowed-tools: Bash(gh:*), Bash(ls:*), Task, AskUserQuestion, TodoWrite
model: sonnet
---

# Create Issue

Create a GitHub issue from an informal description using AI-assisted drafting.

## Parse Arguments

From $ARGUMENTS extract:

| Flag | Description |
|------|-------------|
| (positional) | Description text (required) |
| `-l`, `--labels` | Comma-separated labels |
| `-a`, `--assignee` | Assignee username |
| `-t`, `--template` | Issue template name |
| `-m`, `--milestone` | Milestone name |
| `--no-preview` | Skip preview, create directly |

If no description: Use AskUserQuestion with options "Describe a bug", "Request a feature",
"Suggest an improvement", then prompt for details.

## Phase 1: Template Detection

Check for issue templates:

```bash
ls .github/ISSUE_TEMPLATE/ 2>&1 || echo "NO_TEMPLATES"
```

If templates exist and no `--template` flag: Use AskUserQuestion to offer template selection
with available templates plus "No template" option.

## Phase 2: Issue Drafting

Launch issue drafter agent:

```text
Task (gitx:create-issue:issue-drafter):
  Description: [user's informal description]
  Template: [template name or "none"]
```

If agent identifies ambiguities: Use AskUserQuestion for each clarification.

Store results in `$title`, `$body`, `$suggested_labels`.

## Phase 3: Preview and Edit

Skip if `--no-preview` flag set.

Display preview:

```markdown
## Issue Preview

**Title**: [title]

**Body**:
[body]

**Labels**: [labels]
**Assignee**: [assignee if provided]
```

Use AskUserQuestion with options:
- "Create issue (Recommended)"
- "Edit title"
- "Edit body"
- "Change labels"
- "Cancel"

Handle edits by prompting for changes, then re-display preview.

For label changes:

```bash
gh label list --json name,description --limit 20
```

Use AskUserQuestion with multiSelect to allow label selection.

## Phase 4: Create Issue

Build and execute command:

```bash
gh issue create --title "[title]" --body "[body]" [optional flags]
```

Optional flags: `--label`, `--assignee`, `--template`, `--milestone` (if values set).

If creation fails: Report error and suggest fixes (authentication, label not found, etc.).

## Report Results

```markdown
## Issue Created

- **Number**: #[number]
- **Title**: [title]
- **URL**: [url]

**Next steps**:
- `/gitx:fix-issue [number]` - Start working on issue
- `/gitx:worktree [number]` - Create worktree
- `gh issue view [number]` - View issue
```

## Fallback Mode

If agent fails: Use AskUserQuestion to offer "Use basic mode", "Retry", or "Cancel".

Basic mode prompts for title and body directly, then proceeds to Phase 4.

## Error Handling

| Error | Resolution |
|-------|------------|
| Empty description | Prompt via AskUserQuestion |
| Template not found | Warn, continue without |
| Label not found | Warn, continue without |
| gh not authenticated | Guide to `gh auth login` |
| Permission denied | Check repository access |
