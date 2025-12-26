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

Verify session integrity before resumption:

1. Check that `{{session_path}}` exists. Missing directory indicates invalid path.
2. Check that `{{session_path}}/session-log.md` exists. Missing log indicates incomplete or corrupted session.
3. If not found, inform user and exit. Early exit prevents confusing errors.

### Step 2: Read Session State

Extract session context from log file:

1. Read `{{session_path}}/session-log.md`. Log contains all session metadata.
2. Extract:
   1. Topic. Topic is required for agent prompts.
   2. Depth. Depth determines remaining dialogue rounds.
   3. Last completed phase. Phase determines resume point.
   4. Key insights captured so far. Insights provide context for remaining phases.
   5. Any errors or notes. Errors may require user intervention.

### Step 3: Determine Resume Point

Calculate resumption state to avoid duplicate work:

1. **Last completed phase**: Which phase finished successfully. Completed phases need not be repeated.
2. **Current phase**: Which phase to resume (last completed + 1). Sequential execution maintains dependencies.
3. **Context needed**: What information to pass to the next phase. Context ensures continuity.

### Step 4: Restore Context

Present recovery summary to user for confirmation:

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

Execute remaining phases from the resume point:

1. If resuming Phase 1 (Dialogue): Continue rounds. Dialogue may have partial completion.
2. If resuming Phase 2 (Domain): Run domain explorer. Domain research is atomic.
3. If resuming Phase 3 (Technical): Run technical analyst. Technical analysis is atomic.
4. If resuming Phase 4 (Constraints): Run constraint analyst. Constraint analysis is atomic.
5. If resuming Phase 5 (Requirements): Run requirements synthesizer. Synthesis needs all prior outputs.
6. If resuming Phase 6 (Document): Run specification writer. Document generation is final phase.

### Step 6: Complete Session

After resuming and completing remaining phases, present final summary
as defined in `/brainstorm:start` completion section.

## Error Handling

Handle recovery failures gracefully:

1. **Session Not Found**: Inform user, suggest checking path. Path errors are user-correctable.
2. **Corrupted Log**: Inform user, offer to restart from beginning. Corruption recovery requires full restart.
3. **Missing Context**: Ask user for missing information. User input can fill gaps.

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

1. Session state is determined by parsing session-log.md. Log is the source of truth.
2. All previous phase outputs should be preserved in the session directory. Preserved outputs enable synthesis.
3. If outputs are missing, the command will re-run those phases. Re-running ensures completeness.
