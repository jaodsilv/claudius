---

description: Creates multi-agent orchestrations when coordinating complex workflows.
argument-hint: <orchestration-name> [--plugin <plugin-path>]
allowed-tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "Bash", "TodoWrite"]
---

# Create Orchestration Workflow

Create a command that coordinates multiple agents for complex workflows.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `orchestration_name`: Name for the orchestration (required, kebab-case)
2. `plugin_path`: Plugin directory path (optional, defaults to current directory)

If orchestration_name not provided, ask user to specify.

## Execution

### Phase 1: Validate Context

1. Verify plugin directory exists
2. Check commands/ directory exists
3. Check existing agents available in plugin

Use TodoWrite to track progress:
- [ ] Design architecture
- [ ] Review with user
- [ ] Create orchestration command
- [ ] Create any new agents
- [ ] Validate and test

### Phase 2: Gather Requirements

Use AskUserQuestion to understand the workflow:

```text
Question: "What type of workflow is this?"
Header: "Workflow"
Options:
- Linear workflow (sequential phases)
- Review workflow (iterative refinement)
- Analysis workflow (parallel analysis, merge results)
- Custom workflow (describe phases)
```

```text
Question: "How many phases will this workflow have?"
Header: "Phases"
Options:
- 2-3 phases (simple)
- 4-5 phases (moderate)
- 6+ phases (complex - consider splitting)
```

For each phase, ask:

```text
Question: "Describe phase [N]: What does it do?"
Header: "Phase [N]"
Options: [User provides description]
```

### Phase 3: Design Architecture

Use Task tool with @cc:orchestration-architect agent:

```text
Design orchestration: [orchestration_name]

Workflow type: [from question 1]
Phase count: [from question 2]
Phase descriptions: [from phase questions]

Provide:
1. Recommended coordination pattern
2. Phase definitions with agents
3. Data flow between phases
4. Error handling strategy
5. Complexity assessment
```

Mark todo: Design architecture - Complete

### Phase 4: Review Architecture

Present architecture to user:

```text
Question: "Does this orchestration design look correct?"
Header: "Review"
Options:
- Yes, proceed with implementation
- Modify design (specify changes)
- Redesign from scratch
- Cancel
```

If modifications requested, iterate with architect.

Mark todo: Review with user - Complete

### Phase 5: Create Components

Use Task tool with @cc:orchestration-creator agent:

```text
Create orchestration: [orchestration_name]
Plugin path: [plugin_path]
Architecture: [from design phase]

Create:
1. Main orchestration command in commands/[orchestration_name].md
2. Any new agents needed in agents/
3. Ensure data flow is implemented
4. Add error handling
5. Include compact points
6. Add TodoWrite tracking
```

Mark todos: Create orchestration command, Create any new agents - Complete

### Phase 6: Validate

1. Read created orchestration command
2. Verify all referenced agents exist
3. Check phase structure is complete
4. Validate error handling present

Mark todo: Validate and test - Complete

### Phase 7: Present Results

Show:
1. Orchestration command location
2. Files created (command + any new agents)
3. Workflow phases summary
4. Usage example: `/[plugin]:[orchestration-name] [arguments]`
5. How to test each phase

## Error Handling

If architect agent fails:
- Report error
- Offer to proceed with simple sequential design

If creator agent fails:
- Report partial progress
- Suggest completing manually

If user cancels:
- Clean up any partial files
- Report what was created
