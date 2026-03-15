---
description: Starts interactive brainstorming session for requirements discovery. Use for exploring new features or software concepts.
argument-hint: "[[--topic] <topic>] [--depth <shallow|normal|deep>] [--output-path <path>]"
allowed-tools: Agent, Read, Write, Edit, TaskCreate, TaskGet, TaskList, TaskUpdate, AskUserQuestion, WebSearch, Glob, Grep
model: opus
---

# Brainstorm Session Orchestrator

Coordinates multi-agent workflow for software/feature requirements discovery through Socratic dialogue.

## Parameters

From `$ARGUMENTS`, extract:

- topic: The idea/feature/software concept to explore. Store it in `$topic`
- depth: The depth of the brainstorming. Possible values are: shallow, normal (default), deep. Store it in `$depth`
- output_path: The output path. Defaults to `${worktree}/.thoughts/brainstorm/`. Store it in `$output_path`

## Skill Reference

Use the `brainstorm:validating-workflow` skill for gate checks between phases:

- Gate criteria (1-5)
- Validation patterns
- Phase dependencies

## Initialization Checklist

Use the TaskCreate tool to add the following task(s) to the task list:

<new-tasks>
- [ ] Phase 1: Socratic Dialogue
  - [ ] Gate 1: Post-Dialogue Validation
- [ ] Phase 2: Analysis
  - [ ] Phase 2.1: Domain Exploration
  - [ ] Phase 2.2: Technical Analysis
  - [ ] Phase 2.3: Constraint Analysis
  - [ ] Gate 2: Post-Analysis Validation
- [ ] Phase 3: Analysis Synthesis
  - [ ] Gate 3: Post-Synthesis Validation
- [ ] Phase 4: Requirements Synthesis
  - [ ] Gate 4: Post-Requirements Validation
- [ ] Phase 5: Specification Generation
</new-tasks>

## Phase Execution

> **Note**: Phase 0 (Initialization) is handled by the pre-tool hook (`start.sh`). The hook validates the topic, creates the output directory, and writes `session-log.md`. Resolved values (`output_path`, `depth`, `topic`) are injected via hook context.

### Phase 1: Socratic Dialogue (Batched)

#### Batched Execution

Invoke facilitator in batches of 2-3 rounds instead of individual rounds.

#### Depth Mappings

- `shallow`: 1 batch (3 rounds max)
- `normal`: 2 batches (5 rounds max)
- `deep`: 3 batches (8 rounds max)

#### Batch Invocation

##### 1. **Batch 1** (rounds 1-3)

Use the Agent tool to spawn the agent `brainstorm:facilitator` to conduct dialogue rounds for batch 1:

```markdown
Agent(brainstorm:facilitator):
  prompt:
    Topic: $topic
    Batch number: 1
    Rounds in batch: 3
    Previous context: ""
    output_path: $output_path/facilitator.1.md
```

Facilitator conducts 2-3 rounds internally

**Returns**: Compact summary with clarity assessment

- Append batch result and status to session log
- If clarity="High", proceed to Phase 2

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

##### 2. **Batch 2** (rounds 4-5, if needed)

Skip if depth="shallow" OR clarity="High" from Batch 1

Use the Agent tool to spawn the agent `brainstorm:facilitator` to conduct dialogue rounds for batch 2:

```markdown
Agent(brainstorm:facilitator):
  prompt:
    Topic: $topic
    Batch number: 2
    Rounds in batch: 2
    Previous context: $output_path/facilitator.1.md
    output_path: $output_path/facilitator.2.md
```

**Returns**: Compact summary with clarity assessment

- Append batch result and status to session log
- If depth="normal" AND clarity="Medium+" after this batch, proceed to Phase 2.

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

##### 3. **Batch 3** (rounds 6-8, if depth=deep)

Skip if depth!="deep"

Use the Agent tool to spawn the agent `brainstorm:facilitator` to conduct dialogue rounds for batch 3:

```markdown
Agent(brainstorm:facilitator):
  prompt:
    Topic: $topic
    Batch number: 3
    Rounds in batch: 3
    Previous context: $output_path/facilitator.2.md
    output_path: $output_path/facilitator.3.md
```

**Returns**: Compact summary with clarity assessment

- Append batch result and status to session log
- Proceed to Phase 2 after completion

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

#### Gate 1: Post-Dialogue Validation

Apply Gate 1 criteria from `brainstorm:validating-workflow` skill. If any check fails, run an additional facilitator batch.

### Phase 2: Parallel Analysis

**Execute domain, technical, and constraint analysis in parallel using the Agent tool.**

Use the Agent tool to spawn the following three agents **IN PARALLEL** (all three agents simultaneously). **Wait for all three parallel tasks to complete before proceeding.**

#### Phase 2.1: Domain Exploration

Use the Agent tool to spawn the agent `brainstorm:domain-explorer` to perform domain analysis:

```markdown
Agent(brainstorm:domain-explorer):
  prompt:
    Topic: $topic
    Dialogue summary: [path to last facilitator output file ($output_path/facilitator.X.md)]
    Key requirements areas: {{requirements_areas}}
    Specific domain questions: {{domain_questions}}
```

**Returns**: Domain analysis compact summary

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

#### Phase 2.2: **Technical Analysis**

Use the Agent tool to spawn the agent `brainstorm:technical-analyst` to perform technical analysis:

```markdown
Agent(brainstorm:technical-analyst):
  prompt:
    Topic: $topic
    Dialogue summary: [path to last facilitator output file ($output_path/facilitator.X.md)]
    Initial requirements: {{initial_requirements}}
    Known constraints: {{technical_constraints}}
```

**Returns**: Technical analysis compact summary

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

#### Phase 2.3: Constraint Analysis

Use the Agent tool to spawn the agent `brainstorm:constraint-analyst` to perform constraint analysis:

```markdown
Agent(brainstorm:constraint-analyst):
  prompt:
    Topic: $topic
    Dialogue insights: [path to last facilitator output file ($output_path/facilitator.X.md)]
    Initial scope: {{initial_scope}}
```

**Returns**: Constraint analysis compact summary

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

**Then**:

1. Capture domain explorer output
2. Capture technical analyst output
3. Capture constraint analyst output
4. Append all three reports to session log

### Gate 2: Post-Analysis Validation

Apply Gate 2 criteria from `brainstorm:validating-workflow` skill. If any check fails, identify incomplete analyses and rerun.

### Phase 4.5: Analysis Synthesis

Merge parallel analysis outputs into unified context.

Use the Agent tool to spawn the agent `brainstorm:analysis-synthesizer` to merge analysis outputs into unified context:

```markdown
Agent(brainstorm:analysis-synthesizer):
  prompt:
    Topic: $topic
    Domain analysis: {{domain_compact_summary}}
    Technical analysis: {{technical_compact_summary}}
    Constraint analysis: {{constraint_compact_summary}}
    Dialogue insights: {{phase_1_dialogue_summary}}
```

**Returns**: Unified analysis context for requirements synthesis

Append synthesis summary to session log

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Gate 3: Post-Synthesis Validation

Apply Gate 3 criteria from `brainstorm:validating-workflow` skill. If any check fails, re-run synthesis with clarifications.

### Phase 5: Requirements Synthesis

Use the Agent tool to spawn the agent `brainstorm:requirements-synthesizer` to synthesize structured requirements:

```markdown
Agent(brainstorm:requirements-synthesizer):
  prompt:
    Topic: $topic
    Unified analysis context: {{analysis_synthesizer_output}}
    Original dialogue insights: {{phase_1_dialogue_summary}}
```

**Returns**: Structured requirements document

- Save to `$output_path/requirements.md`
- Append summary to session log

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Gate 4: Post-Requirements Validation

Apply Gate 4 criteria from `brainstorm:validating-workflow` skill. If any check fails, refine and consolidate requirements.

### Phase 6: Specification Generation

Use the Agent tool to spawn the agent `brainstorm:specification-writer` to generate the specification document:

```markdown
Agent(brainstorm:specification-writer):
  prompt:
    Topic: $topic
    Output path: $output_path
    Requirements synthesis: $output_path/requirements.md
    All phase summaries: {{all_phase_summaries}}
    Save to: $output_path/specification.md
```

**Returns**: Complete specification document

- Update session log with completion status

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Gate 5: Post-Specification Validation

Apply Gate 5 criteria from `brainstorm:validating-workflow` skill. If any check fails, refine specification.

## Completion Output

```markdown
## Brainstorm Session Complete

**Topic**: $topic
**Depth**: $depth
**Duration**: [calculated]

### Key Outcomes
1. **Problem Defined**: [summary]
2. **Users Identified**: [summary]
3. **Requirements Captured**: [count] functional, [count] non-functional
4. **Technical Approach**: [summary]
5. **Constraints Documented**: [count] identified

### Generated Artifacts
1. `$output_path/specification.md`
2. `$output_path/requirements.md`
3. `$output_path/session-log.md`

### Recommended Next Steps
1. [Based on session outcomes]

### Open Questions
[List unresolved questions]
```

## Error Handling

| Error | Action |
| :---- | :----- |
| Agent failure | Log error, offer retry or skip |
| User cancellation | Save progress, allow resumption |
| Context overflow | Run `/compact` proactively |

## Usage Examples

```text
/brainstorm:start topic "Real-time collaboration feature"
/brainstorm:start topic "AI code review tool" --depth deep
/brainstorm:start topic "Notification system" --depth normal --output-path ./specs/notifications/
```
