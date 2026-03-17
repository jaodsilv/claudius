---
description: Creates skills when packaging domain knowledge. Use for reusable guidance.
argument-hint: "[[--skill-name] <skill-name>] [--plugin <plugin-path>]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, Bash, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
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

Apply Skill(Skill Development) for skill development best practices.
Apply Skill(cc:authoring-skills) for skill authoring best practices.

Use TaskCreate/TaskUpdate to track progress:

- [ ] Step 1: Validate context
- [ ] Step 2: Gather requirements
- [ ] Step 3: Create directory structure
- [ ] Step 4: Design skill content
- [ ] Step 5: Write skill files
- [ ] Step 6: Validate result

### Step 1: Validate Context

1. Verify plugin directory exists (has .claude-plugin/plugin.json)
2. Check if skills/ directory exists
3. Check if skill already exists

If plugin not found, use the AskUserQuestion tool to ask where to create the skill:

```text
Question: "No plugin found. Where should I create the skill?"
Header: "Location"
Options:
- Create in current directory
- Specify plugin path
- Create new plugin first
```

### Step 2: Gather Requirements

Use the AskUserQuestion tool to ask about the skill's domain:

```text
Question: "What domain knowledge does this skill provide?"
Header: "Domain"
Options:
- Development patterns (coding practices, architecture)
- Tool usage (CLI tools, APIs, frameworks)
- Process guidance (workflows, procedures)
- Domain expertise (industry-specific knowledge)
```

```text
Question: "What resources will this skill include?"
Header: "Resources"
multiSelect: true
Options:
- Reference documents (detailed guides)
- Example files (working code samples)
- Utility scripts (automation tools)
- Templates (starter files)
```

```text
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

### Step 4: Design Skill Content

Mark todo: Step 3 complete, Step 4 in progress.

Use the Agent tool to spawn the agent `cc:skill-creator` to design the skill:

```markdown
Agent(cc:skill-creator):
  Design skill: [skill_name]
  Plugin path: [plugin_path]
  Domain: [answer from domain question]
  Resources needed: [answer from resources question]
  Trigger phrases: [user-provided triggers]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Step 5: Write Skill Files

Mark todo: Step 4 complete, Step 5 in progress.

Use the Agent tool to spawn the agent `cc:component-writer` to write the skill files:

```markdown
Agent(cc:component-writer):
  Write skill files:
  - Skill path: [plugin_path]/skills/[skill_name]
  - Files to write: [list from Step 4]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Step 6: Validate

Mark todo: Step 5 complete, Step 6 in progress.

1. Review the application report from component-writer
2. If any writes failed, report errors to user
3. Read the created SKILL.md to verify
4. Verify frontmatter has name, description, version
5. Check description uses third-person
6. Verify word count is appropriate
7. Check all referenced files exist

Mark todo: Step 6 complete.

### Step 7: Present Results

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

If skill already exists, use the AskUserQuestion tool to ask how to proceed:

```text
Question: "Skill already exists. What would you like to do?"
Header: "Conflict"
Options:
- Overwrite existing skill
- Choose different name
- Merge with existing (add to current)
- Cancel
```

If creation fails:

- Review component-writer's report
- Report specific error
- Clean up partial files
- Suggest manual creation steps
