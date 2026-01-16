---
description: Continues interrupted brainstorming session from last checkpoint. Use when resuming after context overflow or interruption.
allowed-tools: Task, Read, Write, Edit, TodoWrite, AskUserQuestion, Glob
argument-hint: --session-path: <session_path>
model: sonnet
---

# Brainstorm Session Continue

Resumes an interrupted session by reading session log and continuing from last completed phase.

## Parameters

```yaml
properties:
  session_path:
    type: string
    description: Path to session output directory containing session-log.md
    required: true
```

Arguments: `<arguments>$ARGUMENTS</arguments>`

## Skill Reference

Use the `workflow-validation` skill for gate check criteria and session state validation:

- `SKILL.md` - Gate criteria and validation patterns between phases

## Execution Checklist

### Step 1: Validate Session

- [ ] Check `{{session_path}}` exists
- [ ] Check `{{session_path}}/session-log.md` exists
- [ ] Exit with error if not found

### Step 2: Extract Session State

From `{{session_path}}/session-log.md` extract:

- Topic
- Depth
- Last completed phase
- Key insights captured
- Any errors or notes

### Step 3: Determine Resume Point

| Last Completed | Resume From |
|----------------|-------------|
| None | Phase 1 (Dialogue - batched) |
| Phase 1 | Phases 2-4 (Parallel Analysis) |
| Phases 2-4 | Phase 4.5 (Analysis Synthesis) |
| Phase 4.5 | Phase 5 (Requirements) |
| Phase 5 | Phase 6 (Document) |

**Notes**:

- Phase 1 uses batched dialogue (2-3 rounds per invocation)
- Phases 2-4 execute in parallel (domain, technical, constraints)
- Phase 4.5 synthesizes parallel outputs before requirements
- If only some parallel phases completed, resume incomplete ones first

### Step 4: Display Recovery Summary

```markdown
## Session Recovery

**Topic**: {{topic}}
**Depth**: {{depth}}
**Last Completed**: {{last_phase}}
**Resuming From**: Phase {{resume_phase}}

### Progress So Far
{{progress_summary}}

### Resuming...
```

### Step 5: Resume Execution

Execute remaining phases as defined in `/brainstorm:start`.

### Step 6: Complete Session

Present final summary as defined in `/brainstorm:start` completion section.

## Error Handling

| Error | Action |
|-------|--------|
| Session not found | Inform user, suggest checking path |
| Corrupted log | Inform user, offer to restart |
| Missing context | Ask user for missing information |

## Usage Examples

```text
/brainstorm:continue --session-path: ./brainstorm-output/
/brainstorm:continue --session-path: ./specs/auth-feature/
```
