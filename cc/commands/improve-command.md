---
description: Analyze and improve an existing command interactively
argument-hint: <command-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "AskUserQuestion", "Skill", "Task"]
---

# Improve Command Workflow

Analyze an existing command and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `command_path`: Path to command file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

If command_path not provided, ask user to specify.
If focus provided, prioritize analysis of that aspect.

## Execution

### Phase 1: Analysis

Load the improvement-workflow skill:
```
Use Skill tool to load cc:improvement-workflow
```

Use Task tool with @cc:command-improver agent:

```
Analyze command: [command_path]
Focus area: [focus if provided, otherwise "general analysis"]

Evaluate:
1. Frontmatter completeness and correctness
2. Description clarity for /help
3. Argument handling patterns
4. Tool selection appropriateness
5. Instruction clarity (FOR Claude, not TO user)
6. File reference usage
7. Bash execution patterns
8. Integration with agents/skills

Provide improvement suggestions with severity:
- CRITICAL: Must fix (broken functionality)
- HIGH: Should fix (best practice violation)
- MEDIUM: Consider fixing (enhancement opportunity)
- LOW: Nice to have (minor polish)
```

### Phase 2: Present Suggestions

Present analysis results to user.

For each category of suggestions, use AskUserQuestion:

```
Question: "Which severity levels would you like to address?"
Header: "Severity"
multiSelect: true
Options:
- CRITICAL (X issues) - Must fix for functionality
- HIGH (X issues) - Best practice violations
- MEDIUM (X issues) - Enhancement opportunities
- LOW (X issues) - Polish and refinement
```

### Phase 3: Select Improvements

If user selected severity levels, present individual improvements:

```
Question: "Which improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements from selected severity levels]
```

### Phase 4: Apply Changes

For each approved improvement:

1. Show the specific change that will be made (before/after)
2. Apply change using Edit tool
3. Confirm change was applied

### Phase 5: Validation

1. Re-read the modified command
2. Validate frontmatter is still valid YAML
3. Present summary of all changes made
4. Suggest testing the improved command with example usage

## Error Handling

If command file not found:
- Report error clearly
- Suggest using Glob to find commands: `Glob pattern="**/commands/**/*.md"`
- List any similar filenames found

If analysis fails:
- Report partial results if available
- Suggest manual review with checklist:
  1. Check frontmatter YAML syntax
  2. Verify description under 60 characters
  3. Review allowed-tools list
  4. Check argument handling

If edit fails:
- Report specific error (file locked, invalid syntax, etc.)
- Show the intended change for manual application
- Offer to retry or skip to next improvement
