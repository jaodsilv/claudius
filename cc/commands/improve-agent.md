---
description: Improves agents when triggering or prompts need enhancement.
argument-hint: <agent-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
model: sonnet
---

# Improve Agent

Analyze an existing agent and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `agent_path`: Path to agent file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

## Execution

If agent_path not provided:

```text
Use AskUserQuestion:
  Question: "Which agent would you like to improve?"
  Header: "Agent"
  Options:
  - [Use Glob to find agents and list top 4]
```

Delegate to improvement workflow orchestrator:

```text
Use Task tool with @cc:improvement-workflow-orchestrator:

component_type: agent
component_path: [agent_path]
focus: [focus if provided]

Execute the standard 6-phase improvement workflow:
1. Analysis - Call @cc:agent-improver
2. Present suggestions by severity
3. Select improvements
4. Plan changes
5. Apply changes
6. Validate results
```

## Focus Areas

Valid focus areas for agents:
- "triggering" - Description, examples, trigger phrases
- "system prompt" - Clarity, structure, completeness
- "tools" - Tool selection, permissions
- "examples" - Triggering example quality and format
- "responsibilities" - Role definition and scope

## Error Handling

If agent file not found:
- Report error clearly
- Suggest: `Glob pattern="**/agents/**/*.md"`
