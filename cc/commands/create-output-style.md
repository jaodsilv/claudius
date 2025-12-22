---
description: Create a new output-style with formatting guidance
argument-hint: <style-name> [--plugin <plugin-path>]
allowed-tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "Bash"]
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

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if output-styles/ directory exists (create if needed)
3. Check if output-style already exists

If plugin not found:
```
Use AskUserQuestion:
  Question: "No plugin found. Where should I create the output-style?"
  Header: "Location"
  Options:
  - Create in current directory
  - Specify plugin path
  - Create new plugin first
```

### Step 2: Gather Requirements

Use AskUserQuestion to gather output-style details:

```
Question: "What is the primary purpose of this output-style?"
Header: "Purpose"
Options:
- Technical documentation (code, APIs, system design)
- User communication (help text, error messages)
- Report generation (analysis, summaries)
- Custom format (specific structure needed)
```

```
Question: "What tone should the output use?"
Header: "Tone"
Options:
- Professional and formal
- Friendly and conversational
- Concise and direct
- Instructional and educational
```

```
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

### Step 4: Create Output-Style

Use Task tool with @cc:output-style-creator agent:

```
Create output-style: [style_name]
Plugin path: [plugin_path]
Purpose: [answer from purpose question]
Tone: [answer from tone question]
Format elements: [answers from format question]

Generate output-style file with:
1. YAML frontmatter (name, description)
2. Formatting rules section
3. Tone guidelines section
4. Example output section

Write the output-style file to [plugin_path]/output-styles/[style_name].md
```

### Step 5: Validate

1. Read the created output-style file
2. Verify frontmatter is valid YAML
3. Check description is present
4. Verify all sections are included

### Step 6: Present Results

Show:
1. Output-style file location
2. Style description
3. Usage example: Apply style with `/output-style [style-name]`
4. Next steps:
   - Test the output-style
   - Refine formatting rules
   - Add more examples

## Error Handling

If output-style already exists:
```
Use AskUserQuestion:
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
