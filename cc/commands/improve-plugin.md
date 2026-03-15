---
description: Improves plugins comprehensively when preparing for release or audit.
argument-hint: "[[--plugin-path] <plugin-path>] [--focus \"<aspect>\"]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Agent, TaskCreate, TaskGet, TaskList, TaskUpdate
model: opus
---

# Improve Plugin Workflow

Comprehensive plugin improvement with multi-component analysis.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `plugin_path`: Path to plugin directory (optional, defaults to current directory)
2. `focus`: Optional aspect to focus on (--focus "...")

If focus provided, prioritize analysis of that aspect across all components.

## Execution

### Phase 1: Discovery

Use the Skill tool to load the skill `cc:improving-components`:

```markdown
Skill(cc:improving-components)
```

1. Read plugin.json manifest
2. Scan for all components:

```text
Glob pattern="[plugin-path]/commands/**/*.md"
Glob pattern="[plugin-path]/agents/**/*.md"
Glob pattern="[plugin-path]/skills/**/SKILL.md"
Glob pattern="[plugin-path]/hooks/hooks.json"
```

1. Use the TaskCreate tool to add the following task(s) to the task list:

<new-tasks>
- [ ] Analyze plugin structure
- [ ] Analyze commands (X total)
- [ ] Analyze agents (X total)
- [ ] Analyze skills (X total)
- [ ] Synthesize cross-component issues
- [ ] Present improvement roadmap
- [ ] Apply selected improvements
- [ ] Validate final state
</new-tasks>

### Phase 2: Plugin Structure Analysis

Use the Agent tool to spawn the agent `cc:plugin-improver` to analyze the plugin structure:

```markdown
Agent(cc:plugin-improver):
  Analyze plugin structure: [plugin_path]
  Focus area: [focus if provided, otherwise "general analysis"]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Mark todo: Analyze plugin structure - Complete

### Phase 3: Component Analysis

For each component type, launch analysis in parallel if many components, or sequentially if few.

#### Commands Analysis

For each command, use the Agent tool to spawn the agent `cc:command-improver` to analyze the command:

```markdown
Agent(cc:command-improver):
  Analyze command: [command-path]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Mark todo: Analyze commands - Complete

#### Agents Analysis

For each agent, use the Agent tool to spawn the agent `cc:agent-improver` to analyze the agent:

```markdown
Agent(cc:agent-improver):
  Analyze agent: [agent-path]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Mark todo: Analyze agents - Complete

#### Skills Analysis

For each skill, use the Agent tool to spawn the agent `cc:skill-improver` to analyze the skill:

```markdown
Agent(cc:skill-improver):
  Analyze skill: [skill-path]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Mark todo: Analyze skills - Complete

### Phase 4: Synthesize Results

Collect all improvement suggestions.

Mark todo: Synthesize cross-component issues - Complete

Group by severity:

1. **CRITICAL** (blocking issues)
   - Plugin structure issues
   - Security vulnerabilities
   - Broken functionality

2. **HIGH** (significant improvements)
   - Best practice violations
   - Missing documentation
   - Inconsistent patterns

3. **MEDIUM** (enhancements)
   - Optimization opportunities
   - Additional features
   - Improved organization

4. **LOW** (polish)
   - Minor improvements
   - Formatting consistency
   - Additional examples

### Phase 5: Present Roadmap

Use the AskUserQuestion tool to ask which severity levels to address:

```text
Question: "Which severity levels would you like to address?"
Header: "Severity"
multiSelect: true
Options:
- CRITICAL (X issues) - Must fix for functionality
- HIGH (X issues) - Significant improvements
- MEDIUM (X issues) - Enhancement opportunities
- LOW (X issues) - Polish and refinement
```

Mark todo: Present improvement roadmap - Complete

### Phase 6: Select Specific Improvements

For each selected severity level:

1. Present all improvements at that level
2. Allow selection of specific improvements:

```text
Question: "Which [severity] improvements to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements]
```

### Phase 7: Plan Changes

Use the Agent tool to spawn the agent `cc:change-planner` to plan the changes:

```markdown
Agent(cc:change-planner):
  Plan changes for plugin: [plugin_path]

  Selected improvements:
  [List of all selected improvements across severity levels]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Mark todo: Plan changes - Complete

### Phase 8: Apply Improvements

Use the Agent tool to spawn the agent `cc:component-writer` to apply the changes:

```markdown
Agent(cc:component-writer):
  Apply change plan to plugin: [plugin_path]

  Change plan:
  [Change plan from Phase 7]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Update progress using TaskUpdate.

Mark todo: Apply selected improvements - Complete

### Phase 9: Validation

1. Review the application report from component-writer
2. Re-scan plugin structure
3. Verify all components still valid
4. Check cross-references work
5. Validate naming consistency
6. Test README accuracy

Mark todo: Validate final state - Complete

### Phase 10: Summary

Present comprehensive report:

```markdown
## Plugin Improvement Summary: [plugin-name]

### Components Analyzed
- Commands: [X]
- Agents: [Y]
- Skills: [Z]

### Improvements Applied
- Critical: [X of Y]
- High: [X of Y]
- Medium: [X of Y]
- Low: [X of Y]

### Changes Made
1. [Change 1]
2. [Change 2]
...

### Improvements Deferred
1. [Deferred 1] - Reason
2. [Deferred 2] - Reason

### Production Readiness
[Assessment]

### Suggested Next Steps
1. [Next step 1]
2. [Next step 2]
```

## Error Handling

If plugin not found:
- Report error
- Suggest correct path

If component analysis fails:
- Report partial results
- Continue with other components

If too many components:
- Warn about context limits
- Suggest analyzing in batches
