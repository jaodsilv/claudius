---
description: Analyze and improve an existing agent interactively
argument-hint: <agent-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "AskUserQuestion", "Skill", "Task"]
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

### Phase 1: Analysis

Load the improvement-workflow skill:
```
Use Skill tool to load cc:improvement-workflow
```

Use Task tool with @cc:agent-improver agent:

```
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

```
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

```
Question: "Which [category] improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements in category]
```

### Phase 4: Apply Changes

For each approved improvement:

1. Show the specific change (before/after for significant changes)
2. Apply change using Edit tool
3. Confirm change was applied

### Phase 5: Validation

1. Re-read the modified agent
2. Validate frontmatter is still valid YAML
3. Check example block formatting
4. Present summary of all changes made
5. Suggest testing agent triggering with example queries

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

If edit fails:
- Report specific error (file locked, invalid syntax, etc.)
- Show the intended change for manual application
- Offer to retry or skip to next improvement
