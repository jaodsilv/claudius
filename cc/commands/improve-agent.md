---

description: Improves agents when triggering or prompts need enhancement.
argument-hint: <agent-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
---

# Improve Agent Workflow

Analyze an existing agent and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `agent_path`: Path to agent file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

If agent_path not provided, ask user to specify.
If focus provided, prioritize analysis of that aspect.

## Execution

Use TodoWrite to track progress:
- [ ] Phase 1: Analyze agent
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

Use Task tool with @cc:agent-improver agent:

```text
Analyze agent: [agent_path]
Focus area: [focus if provided, otherwise "general analysis"]

Evaluate:
1. Name format (lowercase, hyphens, 3-50 chars)
2. Description with triggering conditions
3. Example blocks (2-4, with context/user/assistant/commentary)
4. Model selection appropriateness
5. Color selection consistency
6. Tool restrictions (least privilege)
7. System prompt structure:
   - Role definition
   - Core responsibilities
   - Analysis process
   - Quality standards
   - Output format
   - Edge case handling
8. Prompt length (500-3000 words ideal)

Provide improvement suggestions with severity levels.
```

### Phase 2: Present Suggestions

Group suggestions by category:

1. Frontmatter improvements (name, model, color, tools)
2. Triggering improvements (description, examples)
3. System prompt improvements (structure, content)

Use AskUserQuestion:

```text
Question: "Which categories would you like to address?"
Header: "Categories"
multiSelect: true
Options:
- Frontmatter (X issues)
- Triggering (X issues)
- System Prompt (X issues)
```

### Phase 3: Select Improvements

For each selected category, present specific improvements:

```text
Question: "Which [category] improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements in category]
```

### Phase 4: Plan Changes

Mark todo: Phase 3 complete, Phase 4 in progress.

Use Task tool with @cc:change-planner agent:

```text
Plan changes for agent: [agent_path]

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
Apply change plan to: [agent_path]

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
3. Re-read the modified agent to verify
4. Check example block formatting is intact
5. Present summary of all changes made
6. Suggest testing agent triggering with example queries

Mark todo: Phase 6 complete.

## Error Handling

If agent file not found:
- Report error clearly
- Suggest using Glob to find agents: `Glob pattern="**/agents/**/*.md"`
- List any similar filenames found

If analysis fails:
- Report partial results if available
- Suggest manual review with checklist:
  1. Check frontmatter YAML syntax
  2. Verify name matches filename
  3. Review description has triggering examples
  4. Check tools list is appropriate

If change planning fails:
- Report error from change-planner agent
- Show the selected improvements for manual review
- Suggest manual ordering if needed

If application fails:
- Review component-writer's application report
- Report which changes succeeded and which failed
- For failed changes, show intended modification for manual application
- Offer to retry failed changes or proceed with successful ones
