---
description: Creates output-styles when defining consistent formatting patterns.
argument-hint: "[[--style-name] <style-name>] [--plugin <plugin-path>]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---

# Create Output-Style Workflow

Create a new output-style following Claude Code best practices.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `style_name`: Name for the new output-style (required, kebab-case)
2. `plugin_path`: Plugin directory path (optional, defaults to current directory)

If style_name not provided, ask user to specify.

## Execution

Apply Skill(cc:validating-components) for output-style validation criteria.

Use TaskCreate/TaskUpdate to track progress:
- [ ] Step 1: Validate context
- [ ] Step 2: Gather requirements
- [ ] Step 3: Create directory
- [ ] Step 4: Design output-style
- [ ] Step 5: Write output-style file
- [ ] Step 6: Validate result

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if output-styles/ directory exists (create if needed)
3. Check if output-style already exists

If plugin not found, use the AskUserQuestion tool to ask where to create the output-style:

```text
Question: "No plugin found. Where should I create the output-style?"
Header: "Location"
Options:
- Create in current directory
- Specify plugin path
- Create new plugin first
```

### Step 2: Gather Requirements

Use the AskUserQuestion tool to ask about the output-style purpose:

```text
Question: "What is the primary purpose of this output-style?"
Header: "Purpose"
Options:
- Technical documentation (code, APIs, system design)
- User communication (help text, error messages)
- Report generation (analysis, summaries)
- Custom format (specific structure needed)
```

```text
Question: "What tone should the output use?"
Header: "Tone"
Options:
- Professional and formal
- Friendly and conversational
- Concise and direct
- Instructional and educational
```

```text
Question: "What formatting elements are important?"
Header: "Format"
multiSelect: true
Options:
- Headings and structure
- Code blocks and syntax highlighting
- Tables and lists
- Examples and samples
```

### Step 3: Create Directory

If output-styles/ directory doesn't exist:

```bash
mkdir -p [plugin_path]/output-styles
```

### Step 4: Design Output-Style

Mark todo: Step 3 complete, Step 4 in progress.

Use the Agent tool to spawn the agent `cc:output-style-creator` to design the output-style:

```markdown
Agent(cc:output-style-creator):
  Design output-style: [style_name]
  Plugin path: [plugin_path]
  Purpose: [answer from purpose question]
  Tone: [answer from tone question]
  Format elements: [answers from format question]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Step 5: Write Output-Style File

Mark todo: Step 4 complete, Step 5 in progress.

Use the Agent tool to spawn the agent `cc:component-writer` to write the output-style file:

```markdown
Agent(cc:component-writer):
  Write output-style file:
  - Path: [plugin_path]/output-styles/[style_name].md
  - Content: [content from Step 4]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Step 6: Validate

Mark todo: Step 5 complete, Step 6 in progress.

1. Review the application report from component-writer
2. If write failed, report error to user
3. Read the created output-style file to verify
4. Verify frontmatter is valid YAML
5. Check description is present
6. Verify all sections are included

Mark todo: Step 6 complete.

### Step 7: Present Results

Show:
1. Output-style file location
2. Style description
3. Usage example: Apply style with `/output-style [style-name]`
4. Next steps:
   - Test the output-style
   - Refine formatting rules
   - Add more examples

## Error Handling

If output-style already exists, use the AskUserQuestion tool to ask how to proceed:

```text
Question: "Output-style already exists. What would you like to do?"
Header: "Conflict"
Options:
- Overwrite existing output-style
- Choose different name
- Cancel
```

If creation fails:
- Report specific error
- Suggest manual creation steps
