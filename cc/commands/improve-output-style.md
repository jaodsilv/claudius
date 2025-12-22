---
description: Analyze and improve an existing output-style interactively
argument-hint: <output-style-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
---

# Improve Output-Style Workflow

Analyze an existing output-style and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `output_style_path`: Path to output-style file or directory (required)
   - Accept file path (e.g., `./output-styles/my-style.md`)
   - Accept directory with style name
2. `focus`: Optional aspect to focus on (--focus "...")

If output_style_path not provided, ask user to specify.
If focus provided, prioritize analysis of that aspect.

## Execution

Use TodoWrite to track progress:
- [ ] Phase 1: Analyze output-style
- [ ] Phase 2: Present suggestions
- [ ] Phase 3: Select improvements
- [ ] Phase 4: Plan changes
- [ ] Phase 5: Apply changes
- [ ] Phase 6: Validate results

### Phase 1: Analysis

Load the improvement-workflow skill:
```
Use Skill tool to load cc:improvement-workflow
```

Use Task tool with @cc:output-style-improver agent:

```
Analyze output-style: [output_style_path]
Focus area: [focus if provided, otherwise "general analysis"]

Evaluate:
1. Frontmatter (name, description)
2. Purpose clarity (when to use this style)
3. Formatting rules completeness
4. Tone guidelines consistency
5. Example coverage and quality
6. Actionability (can Claude follow these rules?)

Provide improvement suggestions with severity levels.
```

### Phase 2: Present Suggestions

Categorize suggestions:

1. Frontmatter improvements (name, description)
2. Formatting rules (clarity, completeness)
3. Tone guidelines (consistency, specificity)
4. Examples (coverage, quality)

Use AskUserQuestion:

```
Question: "Which categories would you like to address?"
Header: "Categories"
multiSelect: true
Options:
- Frontmatter (X issues) - Improve name/description
- Formatting (X issues) - Clarify formatting rules
- Tone (X issues) - Refine tone guidelines
- Examples (X issues) - Add/improve examples
```

### Phase 3: Select Improvements

For each selected category, present specific improvements:

```
Question: "Which [category] improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements in category]
```

### Phase 4: Plan Changes

Mark todo: Phase 3 complete, Phase 4 in progress.

Use Task tool with @cc:change-planner agent:

```
Plan changes for output-style: [output_style_path]

Selected improvements:
[List of selected improvements with their details]

Return a structured change plan with:
- Ordered steps
- Before/after content for each change
- Validation criteria
```

### Phase 5: Apply Changes

Mark todo: Phase 4 complete, Phase 5 in progress.

Use Task tool with @cc:component-writer agent:

```
Apply change plan to: [output_style_path]

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
3. Re-read the modified output-style to verify
4. Validate frontmatter structure
5. Check all sections are present
6. Present summary of all changes made
7. Suggest testing the updated style

Mark todo: Phase 6 complete.

## Analysis Criteria

### Frontmatter Quality

- **name**: Present, kebab-case, descriptive
- **description**: Clear about when to use this style

### Formatting Rules

- **Completeness**: Covers headings, lists, code, tables
- **Clarity**: Rules are specific and actionable
- **Consistency**: No conflicting guidance

### Tone Guidelines

- **Voice**: Active/passive preference stated
- **Formality**: Level is appropriate for purpose
- **Audience**: Target audience defined

### Examples

- **Coverage**: Multiple scenarios demonstrated
- **Quality**: Examples clearly show the style in action
- **Variety**: Different types of output shown

## Error Handling

If output-style not found:
- Report error clearly
- Suggest using Glob to find output-styles: `Glob pattern="**/output-styles/*.md"`

If output-style has invalid frontmatter:
- Report the parsing issue
- Offer to fix the frontmatter structure

If change planning fails:
- Report error from change-planner agent
- Show the selected improvements for manual review

If application fails:
- Review component-writer's application report
- Report which changes succeeded and which failed
- Offer to retry failed changes or proceed with successful ones
