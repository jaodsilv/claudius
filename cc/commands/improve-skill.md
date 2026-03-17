---
description: Improves skills when progressive disclosure or triggers need work.
argument-hint: "[[--skill-path] <skill-path>] [--focus \"<aspect>\"]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, Bash, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---

# Improve Skill

Analyze an existing skill and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:

1. `skill_path`: Path to skill directory or SKILL.md (required)
   - If directory provided, look for SKILL.md within it
2. `focus`: Optional aspect to focus on (--focus "...")

## Execution

If skill_path not provided, use the AskUserQuestion tool to ask which skill to improve:

```text
Question: "Which skill would you like to improve?"
Header: "Skill"
Options:
- [Use Glob to find skills and list top 4]
```

Use the Agent tool to spawn the agent `cc:improvement-workflow-orchestrator` to run the improvement workflow:

```markdown
Agent(cc:improvement-workflow-orchestrator):
  component_type: skill
  component_path: [skill_path]
  focus: [focus if provided]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

## Focus Areas

Valid focus areas for skills:

- "progressive disclosure" - Content organization, reference usage
- "trigger phrases" - Description, activation scenarios
- "writing style" - Third-person description, imperative body
- "word count" - SKILL.md length, content distribution
- "references" - Reference file organization and usage

## Error Handling

If skill not found:

- Report error clearly
- Suggest: `Glob pattern="**/skills/**/SKILL.md"`

If SKILL.md missing in directory:

- Offer to create basic SKILL.md with frontmatter template
