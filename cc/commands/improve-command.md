---
description: Improves commands when workflow or structure needs enhancement.
argument-hint: "[[--command-path] <command-path>] [--focus \"<aspect>\"]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---

# Improve Command

Analyze an existing command and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:

1. `command_path`: Path to command file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

## Execution

If command_path not provided, use the AskUserQuestion tool to ask which command to improve:

```text
Question: "Which command would you like to improve?"
Header: "Command"
Options:
- [Use Glob to find commands and list top 4]
```

Use the Agent tool to spawn the agent `cc:improvement-workflow-orchestrator` to run the improvement workflow:

```markdown
Agent(cc:improvement-workflow-orchestrator):
  component_type: command
  component_path: [command_path]
  focus: [focus if provided]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Focus Areas

Valid focus areas for commands:

- "error handling" - Error paths, validation, recovery
- "argument handling" - Parsing, validation, documentation
- "tool permissions" - allowed-tools, least privilege
- "writing style" - FOR Claude vs TO user style
- "integration" - Agent/skill/file references

## Error Handling

If command file not found:

- Report error clearly
- Suggest: `Glob pattern="**/commands/**/*.md"`
