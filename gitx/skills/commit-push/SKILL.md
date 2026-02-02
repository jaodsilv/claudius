---
description: Commits and pushes changes with smart file grouping and conventional messages
user-invocable: true
argument-hint: "[(--files <file>+)+ | --context <description> | --multi] [--no-push]"
allowed-tools: Bash, Skill, Task, AskUserQuestion
model: haiku
hooks:
  PreToolUse:
    - matcher: "Skill|Task"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/handlers/commit-push-pretool.sh"
          timeout: 60
---

# Commit and Push - Multi-Mode Workflow

Commit changes with conventional messages and optional smart grouping.

## Modes

Extract from $ARGUMENTS or additional context:

- **Explicit files (--files <file0> <file1> ... <fileN>)**: Explicit file groups with one or more `--files`, and each `--files` creates a separate commit. Here identified as `$GROUPS` for the array of file groups, `$GROUPS[i]` for the i-th file group, and `$MODE="lists"`
- **Context Description (--context "<description>")**: Select files matching a contextual description. Here identified as `$DESCRIPTION` for the context description, and `$MODE="context-description"`
- **Multiple Commits (--multi)**: Intelligent grouping of files into multiple logical commits. Here identified as `$MODE="multi-commit"`
- **No push (--no-push)**: Create commits but skip push. Here identified as `$NO_PUSH="true"` if the no-push flag is present, otherwise `$NO_PUSH="false"`.

## Phase 1: Determine File Groups

### If $MODE = "lists"

Each `$GROUPS[i]` represents a separate list of files for a individual commit.

Skip to Phase 2.

### If $MODE = "context-description"

Launch the file-selector agent to determine which files match the description:

```markdown
Task(gitx:commit:file-selector):
  prompt: "Select files for: [$DESCRIPTION]"
```

The agent will generate a list of filepaths.

Store result as a single files group in `$GROUPS[0]`.

### If $MODE = "multi-commit"

Launch the change-grouper agent to intelligently group files:

```markdown
Task(gitx:commit:change-grouper):
  prompt: "Group the changed files into logical commits"
```

The agent will generate an array of file groups.

Store the result as `$GROUPS`

## Phase 3: Generate Commit Messages

For EACH file group in `$GROUPS`, launch the `gitx:committing-conventionally` skill IN PARALLEL:

```markdown
For each $group in $GROUPS:
  Skill(gitx:committing-conventionally):
    args: $group
```

Store a map of agent id to the index of the group in $SKILL_AGENTS_MAP.
The skill will generate a conventional commit message storing in a map of agent id to the message in $MESSAGES.

Wait for all tasks to complete, collecting each result as a pair: `($GROUPS[$SKILL_AGENTS_MAP[$agent_id]], $MESSAGES[$agent_id])`

Store all output in an array $OUTPUTS

## Phase 4: Execute Commits and Push

Build commit pairs structure:

```json
{
  "no_push": $NO_PUSH,
  "pairs": [
    {"files": [$OUTPUTS[0][0]], "message": "$OUTPUTS[0][1]"},
    {"files": [$OUTPUTS[1][0]], "message": "$OUTPUTS[1][1]"}
  ]
}
```

Encode that JSON to base64 and store it in `$JSON_COMMIT_PAIRS`. Execute the commit-push script directly:

```markdown
Bash("${CLAUDE_PLUGIN_ROOT}/hooks/scripts/handlers/commit-push-execute.sh" "$JSON_COMMIT_PAIRS")
```

The script will stage files, create commits, push to remote, and return results.

### Example for the JSON input

```json
{
  "no_push": false,
  "pairs": [
    {"files": ["src/a.ts", "src/b.ts"], "message": "feat(core): ..."},
    {"files": ["test.ts"], "message": "test(core): ..."}
  ]
}
```

## Phase 5: Display Results

The script outputs results directly. Display the formatted output to the user showing:

- Each commit created (SHA, message, files)
- Push status
- PR status (if applicable)

If push failed, follow the hook's suggestion to ask the user about rebase vs force push.

## Error Handling

1. **Push fails**: AskUserQuestion
2. **PR update fails**: Let user know and continue

## Usage Examples

### Default (stage all, one commit)

```markdown
/gitx:commit-push
```

### Explicit file groups

```markdown
/gitx:commit-push --files src/auth.ts tests/auth.test.ts --files README.md
```

Creates two commits: one for auth files, one for README.

### Context-based selection

```markdown
/gitx:commit-push --context "authentication changes"
```

Selects files related to authentication, creates one commit.

### Intelligent multi-commit

```markdown
/gitx:commit-push --multi
```

Analyzes all changes and creates separate commits for each logical group.

### Without push

```markdown
/gitx:commit-push --no-push
```

Creates commit(s) but doesn't push to remote.
