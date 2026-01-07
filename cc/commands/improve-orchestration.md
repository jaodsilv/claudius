---
description: Improves orchestrations when workflow coordination needs optimization.
argument-hint: <orchestration-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
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

If orchestration_path not provided:

```text
Use AskUserQuestion:
  Question: "Which orchestration would you like to improve?"
  Header: "Orchestration"
  Options:
  - [Use Glob to find orchestration commands and list top 4]
```

Load orchestration patterns first:

```text
Use Skill tool to load cc:orchestrating-agents
```

Delegate to improvement workflow orchestrator:

```text
Use Task tool with @cc:improvement-workflow-orchestrator:

component_type: orchestration
component_path: [orchestration_path]
focus: [focus if provided]

Execute the standard 6-phase improvement workflow:
1. Analysis - Call @cc:orchestration-improver
2. Present suggestions by severity
3. Select improvements
4. Plan changes
5. Apply changes
6. Validate results
```

## Architecture Review (Optional)

For complex orchestrations, also invoke:

```text
Use Task tool with @cc:orchestration-architect:
  Review orchestration architecture: [orchestration_path]
  Evaluate pattern appropriateness and alternatives.
```

## Focus Areas

Valid focus areas for orchestrations:
- "phases" - Phase definitions, transitions, gates
- "data flow" - Context passing between phases
- "error handling" - Failure paths, recovery
- "agent coordination" - Task tool usage, delegation
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
