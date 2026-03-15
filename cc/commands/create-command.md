---
description: Creates slash commands when adding plugin functionality. Use for new features.
argument-hint: "[[--command-name] <command-name>] [--plugin <plugin-path>]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---

# Create Command Workflow

Create a new slash command following best practices.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:

1. `command_name`: Name for the new command (required, kebab-case)
2. `plugin_path`: Plugin directory path (optional, defaults to current directory)

If command_name not provided, ask user to specify.

## Execution

Apply Skill(Command Development) for command development best practices.
Apply Skill(cc:validating-components) for validation criteria.

Use TaskCreate/TaskUpdate to track progress:

- [ ] Step 1: Validate context
- [ ] Step 2: Gather requirements
- [ ] Step 3: Design command
- [ ] Step 4: Write command file
- [ ] Step 5: Validate result

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if commands/ directory exists
3. Check if command already exists

If plugin not found at path, use the AskUserQuestion tool to ask where to create the command:

```text
Question: "No plugin found. Where should I create the command?"
Header: "Location"
Options:
- Create in current directory
- Specify plugin path
- Create new plugin first
```

### Step 2: Gather Requirements

Use the AskUserQuestion tool to ask about the command purpose:

```text
Question: "What will this command do?"
Header: "Purpose"
Options:
- Simple task (single action)
- Multi-step workflow (sequential steps)
- Agent delegation (hand off to specialized agent)
- Interactive wizard (user input required)
```

```text
Question: "What tools does this command need?"
Header: "Tools"
multiSelect: true
Options:
- Read/Write (file operations)
- Bash (shell commands)
- Agent (agent delegation)
- AskUserQuestion (user interaction)
```

```text
Question: "What arguments does the command accept?"
Header: "Arguments"
Options:
- No arguments
- Single required argument
- Multiple positional arguments
- Named parameters (--flag value)
```

### Step 3: Design Command

Mark todo: Step 2 complete, Step 3 in progress.

Use the Agent tool to spawn the agent `cc:command-creator` to design the command:

```markdown
Agent(cc:command-creator):
  Design command: [command_name]
  Plugin path: [plugin_path]
  Purpose: [answer from purpose question]
  Tools needed: [answer from tools question]
  Argument style: [answer from arguments question]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Step 4: Write Command File

Mark todo: Step 3 complete, Step 4 in progress.

Use the Agent tool to spawn the agent `cc:component-writer` to write the command file:

```markdown
Agent(cc:component-writer):
  Write new command file:
  - Path: [plugin_path]/commands/[command_name].md
  - Content: [content from Step 3]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Step 5: Validate

Mark todo: Step 4 complete, Step 5 in progress.

1. Review the application report from component-writer
2. If write failed, report error to user
3. Read the created command file to verify
4. Check description is under 60 characters
5. Verify allowed-tools matches requested tools

Mark todo: Step 5 complete.

### Step 6: Present Results

Show:

1. Command file location
2. Command description
3. Usage example: `/[plugin-name]:[command-name] [arguments]`
4. Next steps:
   - Test the command
   - Add to plugin documentation
   - Consider related agents/skills

## Error Handling

If command already exists, use the AskUserQuestion tool to ask how to proceed:

```text
Question: "Command already exists. What would you like to do?"
Header: "Conflict"
Options:
- Overwrite existing command
- Choose different name
- Cancel
```

If creation fails:

- Review component-writer's report
- Report specific error
- Suggest manual creation steps
