---
description: Improves commands when workflow or structure needs enhancement.
argument-hint: <command-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
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

Use TodoWrite to track progress:
- [ ] Phase 1: Analyze command
- [ ] Phase 2: Present suggestions
- [ ] Phase 3: Select improvements
- [ ] Phase 4: Plan changes
- [ ] Phase 5: Apply changes
- [ ] Phase 6: Validate results

### Phase 1: Analysis

Load the improving-components skill:

```text
Use Skill tool to load cc:improving-components
```

Use Task tool with @cc:command-improver agent:

```text
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

```text
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

```text
Question: "Which improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements from selected severity levels]
```

### Phase 4: Plan Changes

Mark todo: Phase 3 complete, Phase 4 in progress.

Use Task tool with @cc:change-planner agent:

```text
Plan changes for command: [command_path]

Selected improvements:
[List of selected improvements with their details]

Analyze dependencies and order changes appropriately.
Return a structured change plan with:
- Ordered steps
- Before/after content for each change
- Validation criteria
```

### Phase 5: Apply Changes

Mark todo: Phase 4 complete, Phase 5 in progress.

Use Task tool with @cc:component-writer agent:

```text
Apply change plan to: [command_path]

Change plan:
[Change plan from Phase 4]

Apply each change in order.
Validate syntax after each edit.
Report success/failure for each step.
```

### Phase 6: Validation

Mark todo: Phase 5 complete, Phase 6 in progress.

1. Review the application report from component-writer
2. If any failures occurred, report them to user
3. Re-read the modified command to verify
4. Present summary of all changes made
5. Suggest testing the improved command with example usage

Mark todo: Phase 6 complete.

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

If change planning fails:
- Report error from change-planner agent
- Show the selected improvements for manual review
- Suggest manual ordering if needed

If application fails:
- Review component-writer's application report
- Report which changes succeeded and which failed
- For failed changes, show intended modification for manual application
- Offer to retry failed changes or proceed with successful ones
