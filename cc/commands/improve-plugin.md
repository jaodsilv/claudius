---
description: Comprehensive plugin-wide improvement with multi-component analysis
argument-hint: <plugin-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
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

Load improvement-workflow skill:

```text
Use Skill tool to load cc:improvement-workflow
```

1. Read plugin.json manifest
2. Scan for all components:

```text
Glob pattern="[plugin-path]/commands/**/*.md"
Glob pattern="[plugin-path]/agents/**/*.md"
Glob pattern="[plugin-path]/skills/**/SKILL.md"
Glob pattern="[plugin-path]/hooks/hooks.json"
```

1. Create TodoWrite with all components to analyze:
   - [ ] Analyze plugin structure
   - [ ] Analyze commands (X total)
   - [ ] Analyze agents (X total)
   - [ ] Analyze skills (X total)
   - [ ] Synthesize cross-component issues
   - [ ] Present improvement roadmap
   - [ ] Apply selected improvements
   - [ ] Validate final state

### Phase 2: Plugin Structure Analysis

Use Task tool with @cc:plugin-improver agent:

```text
Analyze plugin structure: [plugin_path]
Focus area: [focus if provided, otherwise "general analysis"]

Evaluate:
1. plugin.json validity and completeness
2. Directory organization
3. Naming conventions
4. README documentation
5. Cross-component consistency

Focus on plugin-wide issues, not individual components.
```

Mark todo: Analyze plugin structure - Complete

### Phase 3: Component Analysis

For each component type, launch analysis in parallel if many components, or sequentially if few.

#### Commands Analysis

For each command:

```text
Use Task tool with @cc:command-improver:
  Analyze command: [command-path]
  Provide summary of issues by severity.
```

Mark todo: Analyze commands - Complete

#### Agents Analysis

For each agent:

```text
Use Task tool with @cc:agent-improver:
  Analyze agent: [agent-path]
  Provide summary of issues by severity.
```

Mark todo: Analyze agents - Complete

#### Skills Analysis

For each skill:

```text
Use Task tool with @cc:skill-improver:
  Analyze skill: [skill-path]
  Provide summary of issues by severity.
```

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

Use AskUserQuestion:

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

Use Task tool with @cc:change-planner agent:

```text
Plan changes for plugin: [plugin_path]

Selected improvements:
[List of all selected improvements across severity levels]

For plugin-wide changes:
- Group by file
- Order by dependency
- Identify cross-component impacts

Return a structured change plan.
```

Mark todo: Plan changes - Complete

### Phase 8: Apply Improvements

Use Task tool with @cc:component-writer agent:

```text
Apply change plan to plugin: [plugin_path]

Change plan:
[Change plan from Phase 7]

Apply each change in order.
Report success/failure for each step.
```

Update TodoWrite progress.

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
