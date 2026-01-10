---
description: Improves output-styles when formatting rules need refinement.
argument-hint: <output-style-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
model: sonnet
---

# Improve Output-Style

Analyze an existing output-style and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `output_style_path`: Path to output-style file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

## Execution

If output_style_path not provided:

```text
Use AskUserQuestion:
  Question: "Which output-style would you like to improve?"
  Header: "Style"
  Options:
  - [Use Glob to find output-styles and list top 4]
```

Delegate to improvement workflow orchestrator:

```text
Use Task tool with @cc:improvement-workflow-orchestrator:

component_type: output-style
component_path: [output_style_path]
focus: [focus if provided]

Execute the standard 6-phase improvement workflow:
1. Analysis - Call @cc:output-style-improver
2. Present suggestions by severity
3. Select improvements
4. Plan changes
5. Apply changes
6. Validate results
```

## Focus Areas

Valid focus areas for output-styles:
- "formatting rules" - Heading, list, code block rules
- "tone" - Voice, formality, audience alignment
- "examples" - Example coverage and quality
- "clarity" - Actionability, specificity of rules
- "completeness" - Missing sections or guidance

## Error Handling

If output-style not found:
- Report error clearly
- Suggest: `Glob pattern="**/output-styles/*.md"`

If output-style has invalid frontmatter:
- Offer to fix the frontmatter structure
