---
description: Starts interactive brainstorming session for requirements discovery. Use for exploring new features or software concepts.
allowed-tools: Task, Read, Write, Edit, TodoWrite, AskUserQuestion, WebSearch, Glob, Grep, Skill
argument-hint: topic: <topic> --depth: <shallow|normal|deep> --output-path: <output_path>
model: opus
---

# Brainstorm Session Orchestrator

Coordinates multi-agent workflow for software/feature requirements discovery through Socratic dialogue.

## Parameters

```yaml
properties:
  topic:
    type: string
    description: The idea/feature/software concept to explore
    required: true
  depth:
    type: string
    enum: [shallow, normal, deep]
    default: normal
  output_path:
    type: string
    default: ./brainstorm-output/
```

Arguments: `<arguments>$ARGUMENTS</arguments>`

## Skill Reference

Use the `workflow-validation` skill for gate checks between phases:

- Gate criteria (1-5)
- Validation patterns
- Phase dependencies

## Initialization Checklist

- [ ] Validate `$topic` provided
- [ ] Set defaults: `$depth` (normal), `$output_path` (./brainstorm-output/)
- [ ] Create output directory: `mkdir -p {{output_path}}`
- [ ] Initialize TodoWrite with 7 phases (including Analysis Synthesis)
- [ ] Create `{{output_path}}/session-log.md` with header:

```markdown
# Brainstorm Session Log
**Topic**: {{topic}}
**Depth**: {{depth}}
**Started**: [timestamp]
**Status**: In Progress
```

## Phase Execution

### Phase 1: Socratic Dialogue (Batched)

**Batched Execution**: Invoke facilitator in batches of 2-3 rounds instead of individual rounds.

**Depth Mappings**:

- `shallow`: 1 batch (3 rounds max)
- `normal`: 2 batches (5 rounds max)
- `deep`: 3 batches (8 rounds max)

**Batch Invocation**:

1. **Batch 1** (rounds 1-3):
   - Invoke `brainstorm:facilitator` with:

     ```text
     Topic: {{topic}}
     Batch number: 1
     Rounds in batch: 3
     Previous context: [none for first batch]
     ```

   - Facilitator conducts 2-3 rounds internally
   - Receives: Cumulative insights summary + clarity assessment
   - [ ] If clarity="High", proceed to Phase 2
   - [ ] Append batch summary to session log

2. **Batch 2** (rounds 4-5, if needed):
   - Skip if depth="shallow" OR clarity="High" from Batch 1
   - Invoke `brainstorm:facilitator` with:

     ```text
     Topic: {{topic}}
     Batch number: 2
     Rounds in batch: 2
     Previous context: {{batch_1_insights}}
     ```

   - [ ] If depth="normal" AND clarity="Medium+" after this batch, proceed to Phase 2
   - [ ] Append batch summary to session log

3. **Batch 3** (rounds 6-8, if depth=deep):
   - Skip if depth!="deep"
   - Invoke `brainstorm:facilitator` with:

     ```text
     Topic: {{topic}}
     Batch number: 3
     Rounds in batch: 3
     Previous context: {{batch_1_2_insights}}
     ```

   - [ ] Proceed to Phase 2 after completion
   - [ ] Append batch summary to session log

- [ ] Run `/compact` after all batches complete

### Gate 1: Post-Dialogue Validation

Apply Gate 1 criteria from `workflow-validation` skill. If any check fails, run an additional facilitator batch.

### Phases 2-4: Parallel Analysis

**Execute domain, technical, and constraint analysis in parallel using the Task tool.**

Use Task tool to invoke **IN PARALLEL** (all three agents simultaneously):

1. **Domain Exploration** - `brainstorm:domain-explorer`:

   ```text
   Topic: {{topic}}
   Dialogue summary: {{phase_1_dialogue_summary}}
   Key requirements areas: {{requirements_areas}}
   Specific domain questions: {{domain_questions}}
   ```

   Returns: Domain analysis compact summary

2. **Technical Analysis** - `brainstorm:technical-analyst`:

   ```text
   Topic: {{topic}}
   Dialogue summary: {{phase_1_dialogue_summary}}
   Initial requirements: {{initial_requirements}}
   Known constraints: {{technical_constraints}}
   ```

   Returns: Technical analysis compact summary

3. **Constraint Analysis** - `brainstorm:constraint-analyst`:

   ```text
   Topic: {{topic}}
   Dialogue insights: {{phase_1_dialogue_summary}}
   Initial scope: {{initial_scope}}
   ```

   Returns: Constraint analysis compact summary

**Wait for all three parallel tasks to complete before proceeding.**

- [ ] Capture domain explorer output
- [ ] Capture technical analyst output
- [ ] Capture constraint analyst output
- [ ] Append all three reports to session log

### Gate 2: Post-Analysis Validation

Apply Gate 2 criteria from `workflow-validation` skill. If any check fails, identify incomplete analyses and rerun.

### Phase 4.5: Analysis Synthesis

**Merge parallel analysis outputs into unified context.**

Launch `brainstorm:analysis-synthesizer`:

```text
Topic: {{topic}}
Domain analysis: {{domain_compact_summary}}
Technical analysis: {{technical_compact_summary}}
Constraint analysis: {{constraint_compact_summary}}
Dialogue insights: {{phase_1_dialogue_summary}}
```

Returns: Unified analysis context for requirements synthesis

- [ ] Append synthesis summary to session log
- [ ] Run `/compact`

### Gate 3: Post-Synthesis Validation

Apply Gate 3 criteria from `workflow-validation` skill. If any check fails, re-run synthesis with clarifications.

### Phase 5: Requirements Synthesis

Launch `brainstorm:requirements-synthesizer`:

```text
Topic: {{topic}}
Unified analysis context: {{analysis_synthesizer_output}}
Original dialogue insights: {{phase_1_dialogue_summary}}
```

Returns: Structured requirements document

- [ ] Save to `{{output_path}}/requirements.md`
- [ ] Append summary to session log
- [ ] Run `/compact`

### Gate 4: Post-Requirements Validation

Apply Gate 4 criteria from `workflow-validation` skill. If any check fails, refine and consolidate requirements.

### Phase 6: Specification Generation

Launch `brainstorm:specification-writer`:

```text
Topic: {{topic}}
Output path: {{output_path}}
Requirements synthesis: {{requirements_output}}
All phase summaries: {{all_phase_summaries}}
Save to: {{output_path}}/specification.md
```

Returns: Complete specification document

- [ ] Save to `{{output_path}}/specification.md`
- [ ] Update session log with completion status
- [ ] Mark all todos completed

### Gate 5: Post-Specification Validation

Apply Gate 5 criteria from `workflow-validation` skill. If any check fails, refine specification.

## Completion Output

```markdown
## Brainstorm Session Complete

**Topic**: {{topic}}
**Depth**: {{depth}}
**Duration**: [calculated]

### Key Outcomes
1. **Problem Defined**: [summary]
2. **Users Identified**: [summary]
3. **Requirements Captured**: [count] functional, [count] non-functional
4. **Technical Approach**: [summary]
5. **Constraints Documented**: [count] identified

### Generated Artifacts
1. `{{output_path}}/specification.md`
2. `{{output_path}}/requirements.md`
3. `{{output_path}}/session-log.md`

### Recommended Next Steps
1. [Based on session outcomes]

### Open Questions
[List unresolved questions]
```

## Error Handling

| Error | Action |
|-------|--------|
| Agent failure | Log error, offer retry or skip |
| User cancellation | Save progress, allow resumption |
| Context overflow | Run `/compact` proactively |

## Usage Examples

```text
/brainstorm:start topic: "Real-time collaboration feature"
/brainstorm:start topic: "AI code review tool" --depth: deep
/brainstorm:start topic: "Notification system" --depth: normal --output-path: ./specs/notifications/
```
