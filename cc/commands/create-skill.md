---
description: Create a new skill with progressive disclosure structure
argument-hint: <skill-name> [--plugin <plugin-path>]
allowed-tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "Bash"]
---

# Create Skill Workflow

Create a new skill following progressive disclosure principles.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `skill_name`: Name for the new skill (required, kebab-case)
2. `plugin_path`: Plugin directory path (optional, defaults to current directory)

If skill_name not provided, ask user to specify.

## Execution

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if skills/ directory exists
3. Check if skill already exists

If plugin not found:
```
Use AskUserQuestion:
  Question: "No plugin found. Where should I create the skill?"
  Header: "Location"
  Options:
  - Create in current directory
  - Specify plugin path
  - Create new plugin first
```

### Step 2: Gather Requirements

Use AskUserQuestion to gather skill details:

```
Question: "What domain knowledge does this skill provide?"
Header: "Domain"
Options:
- Development patterns (coding practices, architecture)
- Tool usage (CLI tools, APIs, frameworks)
- Process guidance (workflows, procedures)
- Domain expertise (industry-specific knowledge)
```

```
Question: "What resources will this skill include?"
Header: "Resources"
multiSelect: true
Options:
- Reference documents (detailed guides)
- Example files (working code samples)
- Utility scripts (automation tools)
- Templates (starter files)
```

```
Question: "What should trigger this skill?"
Header: "Triggers"
Options: [User will provide custom trigger phrases]
```

For triggers, prompt user to provide 3-5 example phrases that should load this skill.

### Step 3: Create Directory Structure

```bash
mkdir -p [plugin_path]/skills/[skill_name]/references
mkdir -p [plugin_path]/skills/[skill_name]/examples
mkdir -p [plugin_path]/skills/[skill_name]/scripts
```

### Step 4: Create Skill

Use Task tool with @cc:skill-creator agent:

```
Create skill: [skill_name]
Plugin path: [plugin_path]
Domain: [answer from domain question]
Resources needed: [answer from resources question]
Trigger phrases: [user-provided triggers]

Follow plugin-dev skill-development skill for structure.
Use progressive disclosure: lean SKILL.md (<2000 words), details in references/.

Create:
1. SKILL.md with frontmatter and core content
2. Reference files if domain requires detailed documentation
3. Example files if practical demonstrations needed
```

### Step 5: Validate

1. Read the created SKILL.md
2. Verify frontmatter has name, description, version
3. Check description uses third-person
4. Verify word count is appropriate
5. Check all referenced files exist

### Step 6: Present Results

Show:
1. Skill directory location
2. Files created
3. Trigger phrases configured
4. How to test: Ask questions using trigger phrases
5. Next steps:
   - Add more detailed references if needed
   - Create working examples
   - Add utility scripts

## Error Handling

If skill already exists:
```
Use AskUserQuestion:
  Question: "Skill already exists. What would you like to do?"
  Header: "Conflict"
  Options:
  - Overwrite existing skill
  - Choose different name
  - Merge with existing (add to current)
  - Cancel
```

If creation fails:
- Report specific error
- Clean up partial files
- Suggest manual creation steps
