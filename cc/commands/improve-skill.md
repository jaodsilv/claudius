---
description: Improves skills when progressive disclosure or triggers need work.
argument-hint: <skill-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "Bash", "TodoWrite"]
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

If skill_path not provided:

```text
Use AskUserQuestion:
  Question: "Which skill would you like to improve?"
  Header: "Skill"
  Options:
  - [Use Glob to find skills and list top 4]
```

Delegate to improvement workflow orchestrator:

```text
Use Task tool with @cc:improvement-workflow-orchestrator:

component_type: skill
component_path: [skill_path]
focus: [focus if provided]

Execute the standard 6-phase improvement workflow:
1. Analysis - Call @cc:skill-improver
2. Present suggestions by severity
3. Select improvements
4. Plan changes
5. Apply changes
6. Validate results
```

## Focus Areas

Valid focus areas for skills:

- "progressive disclosure" - Content organization, reference usage
- "trigger phrases" - Description, activation scenarios
- "writing style" - Third-person description, imperative body
- "word count" - SKILL.md length, content distribution
- "references" - Reference file organization and usage

## Special Operations

For content reorganization (moving content from SKILL.md to references/):

- The orchestrator handles creating new reference files first
- Then updates SKILL.md with reference pointers
- Creates missing directories if needed (examples/, scripts/)

## Error Handling

If skill not found:

- Report error clearly
- Suggest: `Glob pattern="**/skills/**/SKILL.md"`

If SKILL.md missing in directory:

- Offer to create basic SKILL.md with frontmatter template
