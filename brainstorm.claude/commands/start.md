---
description: Starts interactive brainstorming session for requirements discovery. Use for exploring new features or software concepts.
allowed-tools: Task, Read, Write, Edit, TodoWrite, AskUserQuestion, WebSearch, Glob, Grep
argument-hint: topic: <topic> --depth: <shallow|normal|deep> --output-path: <output_path>
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

## Initialization Checklist

- [ ] Validate `$topic` provided
- [ ] Set defaults: `$depth` (normal), `$output_path` (./brainstorm-output/)
- [ ] Create output directory: `mkdir -p {{output_path}}`
- [ ] Initialize TodoWrite with 6 phases
- [ ] Create `{{output_path}}/session-log.md` with header:

```markdown
# Brainstorm Session Log
**Topic**: {{topic}}
**Depth**: {{depth}}
**Started**: [timestamp]
**Status**: In Progress
```

## Phase Execution

### Phase 1: Socratic Dialogue (Interactive)

**Rounds**: shallow=3, normal=5, deep=8

For each round, launch `brainstorm-facilitator`:

```text
Topic: {{topic}}
Previous insights: {{previous_insights}}
Areas to explore: {{areas_to_explore}}
Round: {{current_round}} of {{max_rounds}}
```

- [ ] Append dialogue summary to session log after each round
- [ ] Early exit if clarity="High" AND rounds >= 2
- [ ] Run `/compact` after all rounds

### Phase 2: Domain Exploration

Launch `brainstorm-domain-explorer`:

```text
Topic: {{topic}}
Key requirements areas: {{requirements_areas}}
Specific domain questions: {{domain_questions}}
```

- [ ] Append domain report to session log
- [ ] Run `/compact`

### Phase 3: Technical Analysis

Launch `brainstorm-technical-analyst`:

```text
Topic: {{topic}}
Requirements summary: {{requirements_summary}}
Domain insights: {{domain_insights}}
Known constraints: {{technical_constraints}}
```

- [ ] Append technical report to session log
- [ ] Run `/compact`

### Phase 4: Constraint Analysis

Launch `brainstorm-constraint-analyst`:

```text
Topic: {{topic}}
Dialogue insights: {{dialogue_insights}}
Domain insights: {{domain_insights}}
Technical analysis: {{technical_summary}}
```

- [ ] Append constraint report to session log
- [ ] Run `/compact`

### Phase 5: Requirements Synthesis

Launch `brainstorm-requirements-synthesizer`:

```text
Topic: {{topic}}
Dialogue insights: {{dialogue_insights}}
Domain research: {{domain_research}}
Technical analysis: {{technical_analysis}}
Constraints: {{constraints}}
```

- [ ] Save to `{{output_path}}/requirements.md`
- [ ] Append summary to session log
- [ ] Run `/compact`

### Phase 6: Document Generation

Launch `brainstorm-specification-writer`:

```text
Topic: {{topic}}
Output path: {{output_path}}
Session outputs: [all phase outputs]
Save to: {{output_path}}/specification.md
```

- [ ] Update session log with completion status
- [ ] Mark all todos completed

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
