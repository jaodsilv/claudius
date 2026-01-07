---
description: Improves commands when workflow or structure needs enhancement.
argument-hint: <command-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
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

If command_path not provided:

```text
Use AskUserQuestion:
  Question: "Which command would you like to improve?"
  Header: "Command"
  Options:
  - [Use Glob to find commands and list top 4]
```

Delegate to improvement workflow orchestrator:

```text
Use Task tool with @cc:improvement-workflow-orchestrator:

component_type: command
component_path: [command_path]
focus: [focus if provided]

Execute the standard 6-phase improvement workflow:
1. Analysis - Call @cc:command-improver
2. Present suggestions by severity
3. Select improvements
4. Plan changes
5. Apply changes
6. Validate results
```

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
