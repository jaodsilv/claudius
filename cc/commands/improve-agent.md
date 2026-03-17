---
description: Improves agents when triggering or prompts need enhancement.
argument-hint: "[[--agent-path] <agent-path>] [--focus \"<aspect>\"]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
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

If agent_path not provided, use the AskUserQuestion tool to ask which agent to improve:

```text
Question: "Which agent would you like to improve?"
Header: "Agent"
Options:
- [Use Glob to find agents and list top 4]
```

Use the Agent tool to spawn the agent `cc:improvement-workflow-orchestrator` to run the improvement workflow:

```markdown
Agent(cc:improvement-workflow-orchestrator):
  component_type: agent
  component_path: [agent_path]
  focus: [focus if provided]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

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
