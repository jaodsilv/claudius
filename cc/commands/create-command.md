---
description: Create a new slash command with best practices guidance
argument-hint: <command-name> [--plugin <plugin-path>]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
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

Use TodoWrite to track progress:
- [ ] Step 1: Validate context
- [ ] Step 2: Gather requirements
- [ ] Step 3: Design command
- [ ] Step 4: Write command file
- [ ] Step 5: Validate result

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if commands/ directory exists
3. Check if command already exists

If plugin not found at path:

```text
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
- Task (agent delegation)
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

Use Task tool with @cc:command-creator agent:

```text
Design command: [command_name]
Plugin path: [plugin_path]
Purpose: [answer from purpose question]
Tools needed: [answer from tools question]
Argument style: [answer from arguments question]

Generate command content following plugin-dev command-development skill.
Return the complete command content (frontmatter + body) for writing.
Do NOT write the file - return content only.
```

### Step 4: Write Command File

Mark todo: Step 3 complete, Step 4 in progress.

Use Task tool with @cc:component-writer agent:

```text
Write new command file:
- Path: [plugin_path]/commands/[command_name].md
- Content: [content from Step 3]

Validate syntax after writing.
Report success/failure.
```

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

If command already exists:

```text
Use AskUserQuestion:
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
