---
description: Improves output-styles when formatting rules need refinement.
argument-hint: "[[--output-style-path] <output-style-path>] [--focus \"<aspect>\"]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
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

If output_style_path not provided, use the AskUserQuestion tool to ask which output-style to improve:

```text
Question: "Which output-style would you like to improve?"
Header: "Style"
Options:
- [Use Glob to find output-styles and list top 4]
```

Use the Agent tool to spawn the agent `cc:improvement-workflow-orchestrator` to run the improvement workflow:

```markdown
Agent(cc:improvement-workflow-orchestrator):
  component_type: output-style
  component_path: [output_style_path]
  focus: [focus if provided]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

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
