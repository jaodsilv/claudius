---
description: Create a new slash command with best practices guidance
argument-hint: <command-name> [--plugin <plugin-path>]
allowed-tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "Bash"]
---

# Create Command Workflow

Create a new slash command following plugin-dev best practices.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `command_name`: Name for the new command (required, kebab-case)
2. `plugin_path`: Plugin directory path (optional, defaults to current directory)

If command_name not provided, ask user to specify.

## Execution

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if commands/ directory exists
3. Check if command already exists

If plugin not found at path:
```
Use AskUserQuestion:
  Question: "No plugin found. Where should I create the command?"
  Header: "Location"
  Options:
  - Create in current directory
  - Specify plugin path
  - Create new plugin first
```

### Step 2: Gather Requirements

Use AskUserQuestion to gather command details:

```
Question: "What will this command do?"
Header: "Purpose"
Options:
- Simple task (single action)
- Multi-step workflow (sequential steps)
- Agent delegation (hand off to specialized agent)
- Interactive wizard (user input required)
```

```
Question: "What tools does this command need?"
Header: "Tools"
multiSelect: true
Options:
- Read/Write (file operations)
- Bash (shell commands)
- Task (agent delegation)
- AskUserQuestion (user interaction)
```

```
Question: "What arguments does the command accept?"
Header: "Arguments"
Options:
- No arguments
- Single required argument
- Multiple positional arguments
- Named parameters (--flag value)
```

### Step 3: Create Command

Use Task tool with @cc:command-creator agent:

```
Create command: [command_name]
Plugin path: [plugin_path]
Purpose: [answer from purpose question]
Tools needed: [answer from tools question]
Argument style: [answer from arguments question]

Generate command following plugin-dev command-development skill.
Write the command file to [plugin_path]/commands/[command_name].md
```

### Step 4: Validate

1. Read the created command file
2. Verify frontmatter is valid
3. Check description is under 60 characters
4. Verify allowed-tools matches requested tools

### Step 5: Present Results

Show:
1. Command file location
2. Command description
3. Usage example: `/[plugin-name]:[command-name] [arguments]`
4. Next steps:
   - Test the command
   - Add to plugin documentation
   - Consider related agents/skills

## Error Handling

If command already exists:
```
Use AskUserQuestion:
  Question: "Command already exists. What would you like to do?"
  Header: "Conflict"
  Options:
  - Overwrite existing command
  - Choose different name
  - Cancel
```

If creation fails:
- Report specific error
- Suggest manual creation steps
