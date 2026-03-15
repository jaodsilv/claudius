---
description: Improves orchestrations when workflow coordination needs optimization.
argument-hint: "[[--orchestration-path] <orchestration-path>] [--focus \"<aspect>\"]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---

# Improve Orchestration

Analyze and improve a multi-agent orchestration interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:

1. `orchestration_path`: Path to orchestration file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

## Execution

If orchestration_path not provided, use the AskUserQuestion tool to ask which orchestration to improve:

```text
Question: "Which orchestration would you like to improve?"
Header: "Orchestration"
Options:
- [Use Glob to find orchestration commands and list top 4]
```

Load orchestration patterns first. Use the Skill tool to load the skill `cc:orchestrating-agents`:

```markdown
Skill(cc:orchestrating-agents)
```

Use the Agent tool to spawn the agent `cc:improvement-workflow-orchestrator` to run the improvement workflow:

```markdown
Agent(cc:improvement-workflow-orchestrator):
  component_type: orchestration
  component_path: [orchestration_path]
  focus: [focus if provided]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Architecture Review (Optional)

For complex orchestrations, also invoke. Use the Agent tool to spawn the agent `cc:orchestration-architect` to review the architecture:

```markdown
Agent(cc:orchestration-architect):
  Review orchestration architecture: [orchestration_path]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Focus Areas

Valid focus areas for orchestrations:

- "phases" - Phase definitions, transitions, gates
- "data flow" - Context passing between phases
- "error handling" - Failure paths, recovery
- "agent coordination" - Agent tool usage, delegation
- "context management" - Compact points, state tracking
- "parallelism" - Concurrent execution opportunities

## Special Operations

For architectural changes that require restructuring:

- Creating new agent files
- Updating orchestration references
- Splitting agent responsibilities

The orchestrator handles file creation before reference updates.

## Error Handling

If orchestration not found:

- Report error clearly
- Suggest: `Glob pattern="**/commands/**/*.md"`
