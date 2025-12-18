---
description: Continue an interrupted brainstorming session from where it left off
allowed-tools: Task, Read, Write, Edit, TodoWrite, AskUserQuestion, Glob
argument-hint: --session-path: <session_path>
---

# Brainstorm Session Continue

Continue an interrupted brainstorming session by reading the session log and
resuming from the last completed phase.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments and extract:

1. `$session_path`: Path to the session output directory (required)

## Parameters Schema

```yaml
brainstorm-continue-arguments:
  type: object
  description: Arguments for /brainstorm:continue command
  properties:
    session_path:
      type: string
      description: Path to the session output directory containing session-log.md
  required:
    - session_path
```

## Execution Workflow

### Step 1: Validate Session

1. Check that `{{session_path}}` exists
2. Check that `{{session_path}}/session-log.md` exists
3. If not found, inform user and exit

### Step 2: Read Session State

1. Read `{{session_path}}/session-log.md`
2. Extract:
   1. Topic
   2. Depth
   3. Last completed phase
   4. Key insights captured so far
   5. Any errors or notes

### Step 3: Determine Resume Point

Based on session log, identify:

1. **Last completed phase**: Which phase finished successfully
2. **Current phase**: Which phase to resume (last completed + 1)
3. **Context needed**: What information to pass to the next phase

### Step 4: Restore Context

Present to user:

```markdown
## Session Recovery

**Topic**: {{topic}}
**Depth**: {{depth}}
**Last Completed Phase**: {{last_phase}}
**Resuming From**: Phase {{resume_phase}}

### Progress So Far

{{progress_summary}}

### Resuming...
```

### Step 5: Resume Execution

Continue with the appropriate phase from `/brainstorm:start`:

1. If resuming Phase 1 (Dialogue): Continue rounds
2. If resuming Phase 2 (Domain): Run domain explorer
3. If resuming Phase 3 (Technical): Run technical analyst
4. If resuming Phase 4 (Constraints): Run constraint analyst
5. If resuming Phase 5 (Requirements): Run requirements synthesizer
6. If resuming Phase 6 (Document): Run specification writer

### Step 6: Complete Session

After resuming and completing remaining phases, present final summary
as defined in `/brainstorm:start` Phase 7.

## Error Handling

1. **Session Not Found**: Inform user, suggest checking path
2. **Corrupted Log**: Inform user, offer to restart from beginning
3. **Missing Context**: Ask user for missing information

## Usage Examples

### Resume Session

```text
/brainstorm:continue --session-path: ./brainstorm-output/
```

### Resume Specific Session

```text
/brainstorm:continue --session-path: ./specs/auth-feature/
```

## Notes

1. Session state is determined by parsing session-log.md
2. All previous phase outputs should be preserved in the session directory
3. If outputs are missing, the command will re-run those phases
