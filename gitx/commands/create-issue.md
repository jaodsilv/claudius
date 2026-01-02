---
description: Create a GitHub issue from informal description
argument-hint: "<description> [-l labels] [-a assignee] [-t template] [-m milestone] [--no-preview]"
allowed-tools: Bash(gh:*), Bash(ls:*), Task, AskUserQuestion, TodoWrite
---

# Create Issue

Create a GitHub issue from an informal description. An agent analyzes your
description to generate a structured title and detailed body, with optional
template support and preview before creation.

## Parse Arguments

From $ARGUMENTS, extract:

1. Description (required): The informal description text (can be quoted or unquoted)
2. `-l` or `--labels`: Comma-separated labels (e.g., `-l bug,enhancement`)
3. `-a` or `--assignee`: Assignee username (e.g., `-a @me` or `-a username`)
4. `-t` or `--template`: Issue template name (e.g., `-t "Bug Report"`)
5. `-m` or `--milestone`: Milestone name
6. `--no-preview`: Skip preview and create directly

If no description provided:

Use AskUserQuestion:

```text
Question: "What issue would you like to create?"
Header: "Describe"
Options:
1. "Describe a bug" - Something is broken or not working correctly
2. "Request a feature" - New functionality or capability
3. "Suggest an improvement" - Enhancement to existing functionality
4. "Cancel" - Abort issue creation
```

For "Describe a bug", prompt:

```text
"Describe the bug you encountered. Include what you expected vs what happened."
```

For "Request a feature", prompt:

```text
"Describe the feature you'd like. Include the problem it solves and any
ideas for implementation."
```

For "Suggest an improvement", prompt:

```text
"Describe what you'd like to improve and why."
```

## Initialize Progress Tracking

```text
TodoWrite:
1. [ ] Check for issue templates
2. [ ] Draft issue content
3. [ ] Preview and edit
4. [ ] Create issue
```

## Phase 1: Template Detection

Mark "Check for issue templates" as in_progress.

### Check for Issue Templates

```powershell
# Check for issue templates in repository
$templates = Get-ChildItem -Path ".github/ISSUE_TEMPLATE/" -ErrorAction SilentlyContinue
if (-not $templates) {
  $templates = Get-ChildItem -Path ".github/ISSUE_TEMPLATE.md" -ErrorAction SilentlyContinue
}
if (-not $templates) { echo "NO_TEMPLATES" } else { $templates }
```

If templates exist and no `--template` flag provided:

Parse template names from directory listing.

Use AskUserQuestion:

```text
Question: "Issue templates are available. Would you like to use one?"
Header: "Template"
Options:
1. "[Template 1 name]" - Use this template
2. "[Template 2 name]" - Use this template
3. "No template" - Create without template
```

Store selected template in `$template` variable.

If `--template` flag provided:

1. Validate template exists
2. If not found, warn and continue without template

Mark "Check for issue templates" as completed.

## Phase 2: Issue Drafting

Mark "Draft issue content" as in_progress.

Launch issue drafter agent:

```text
Task (gitx:issue-drafter):
  Description: [user's informal description]
  Template: [template name if selected, or "none"]

  Analyze the description and generate:
  1. Structured issue title (clear, concise, actionable)
  2. Detailed issue body with appropriate sections
  3. Suggested labels (if not provided via flag)
  4. Identified ambiguities requiring clarification
```

Wait for agent to complete.

### Handle Clarification Requests

If agent identifies ambiguities:

Use AskUserQuestion for each ambiguity:

```text
Question: "[Clarification question from agent]"
Header: "Clarify"
Options:
[Context-specific options based on ambiguity type]
```

Update draft with clarifications.

Store results:

1. `$title`: Generated issue title
2. `$body`: Generated issue body
3. `$suggested_labels`: Agent-suggested labels (if no `--labels` flag)

Mark "Draft issue content" as completed.

## Phase 3: Preview and Edit

Mark "Preview and edit" as in_progress.

If `--no-preview` flag is set, skip to Phase 4.

### Present Preview

```markdown
## Issue Preview

### Title
[generated title]

### Body
[generated body]

---

### Metadata
1. **Labels**: [labels from flag or suggestions]
2. **Assignee**: [assignee if provided]
3. **Template**: [template name or "none"]
4. **Milestone**: [milestone if provided]
```

Use AskUserQuestion:

```text
Question: "Review the issue preview. How would you like to proceed?"
Header: "Action"
Options:
1. "Create issue (Recommended)" - Create with current content
2. "Edit title" - Modify the title
3. "Edit body" - Modify the body
4. "Change labels" - Modify labels
5. "Cancel" - Abort issue creation
```

### Handle Edit Requests

**Edit title**:

Use AskUserQuestion:

```text
Question: "Current title: '[current title]'. Enter the new title or describe
what to change:"
Header: "Title"
Options:
1. "Make it shorter" - Condense the title
2. "Make it more specific" - Add detail
3. "Change focus" - Emphasize different aspect
```

Update `$title` and re-show preview.

**Edit body**:

Use AskUserQuestion:

```text
Question: "What would you like to change in the body?"
Header: "Edit Body"
Options:
1. "Add more detail" - Expand sections
2. "Simplify" - Remove unnecessary content
3. "Add section" - Include additional section
4. "Remove section" - Delete a section
```

Update `$body` and re-show preview.

**Change labels**:

```bash
# Get available labels
gh label list --json name,description --limit 20
```

Use AskUserQuestion:

```text
Question: "Select labels to apply (current: [current labels])"
Header: "Labels"
multiSelect: true
Options:
[List available labels from repository]
```

Mark "Preview and edit" as completed.

## Phase 4: Create Issue

Mark "Create issue" as in_progress.

### Build Command

Construct `gh issue create` command with all provided options.

Base command:

```bash
gh issue create --title "[title]" --body "[body]"
```

Add optional flags if values are set:

1. If `$labels` set: `--label "[labels]"`
2. If `$assignee` set: `--assignee "[assignee]"`
3. If `$template` set: `--template "[template]"`
4. If `$milestone` set: `--milestone "[milestone]"`

### Execute Creation

```bash
gh issue create --title "[title]" --body "[body]" [optional flags]
```

Capture output (issue URL and number).

If command fails:

1. Report error message
2. Suggest common fixes:
   1. Authentication: `gh auth login`
   2. Label not found: Check label name with `gh label list`
   3. Milestone not found: Check milestone name
3. Exit

Mark "Create issue" as completed.

## Report Results

Show creation confirmation:

```markdown
## Issue Created

### Details
1. **Issue Number**: #[number]
2. **Title**: [title]
3. **URL**: [url]
4. **Labels**: [labels]
5. **Assignee**: [assignee]

### Next Steps

To start working on this issue:

/gitx:fix-issue [number]

Or create a worktree:

/gitx:worktree [number]

To view the issue:

gh issue view [number]
```

## Fallback Mode

If agent delegation fails:

Use AskUserQuestion:

```text
Question: "Issue drafting encountered an issue. Continue with basic mode?"
Header: "Fallback"
Options:
1. "Yes, use basic mode" - Manual title/body input
2. "Retry drafting" - Try agent again
3. "Cancel" - Abort
```

### Basic Mode

Prompt for title:

```text
Question: "Enter issue title:"
Header: "Title"
Options:
1. "Bug: [description]" - Format as bug
2. "Feature: [description]" - Format as feature request
3. "Custom title" - Enter your own
```

Prompt for body:

```text
Question: "Enter issue description (or skip for empty body):"
Header: "Body"
Options:
1. "Use description as body" - Use original description
2. "Enter custom body" - Provide detailed body
3. "Skip body" - Create with title only
```

Proceed to Phase 4.

## Error Handling

1. **Empty description**: Prompt for input via AskUserQuestion.
2. **Template not found**: Warn and continue without template.
3. **Label not found**: Warn and continue without that label.
4. **Milestone not found**: Warn and continue without milestone.
5. **gh not authenticated**: Guide to `gh auth login`.
6. **gh command failure**: Report error message and stop.
7. **Agent failure**: Fall back to basic mode with manual input.
8. **Permission denied**: Check repository write access.
