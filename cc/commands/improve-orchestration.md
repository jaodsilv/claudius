---
description: Analyze and improve an existing orchestration interactively
argument-hint: <orchestration-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "TodoWrite"]
---

# Improve Orchestration Workflow

Analyze and improve a multi-agent orchestration interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `orchestration_path`: Path to orchestration file (required)
2. `focus`: Optional aspect to focus on (--focus "...")

If orchestration_path not provided, ask user to specify.
If focus provided, prioritize analysis of that aspect.

## Execution

### Phase 1: Analysis

Load the improvement-workflow skill:
```
Use Skill tool to load cc:improvement-workflow
```

Load orchestration patterns:
```
Use Skill tool to load cc:orchestration-patterns
```

Use TodoWrite to track:
- [ ] Analyze workflow structure
- [ ] Review architecture
- [ ] Present suggestions
- [ ] Apply improvements
- [ ] Validate changes

Use Task tool with @cc:orchestration-improver agent:

```
Analyze orchestration: [orchestration_path]
Focus area: [focus if provided, otherwise "general analysis"]

Evaluate:
1. Workflow clarity and completeness
2. Phase definitions and transitions
3. Agent delegation patterns
4. Data flow between phases
5. Error handling coverage
6. Context management (compact points)
7. User interaction points
8. Gate conditions
9. State tracking

Provide improvement suggestions with severity levels.
```

Mark todo: Analyze workflow structure - Complete

### Phase 2: Architecture Review

Use Task tool with @cc:orchestration-architect agent:

```
Review orchestration architecture: [orchestration-path]

Evaluate:
1. Coordination pattern appropriateness
2. Agent responsibility distribution
3. Complexity balance
4. Extensibility and maintainability
5. Alternative architectures to consider

Provide architectural recommendations.
```

Mark todo: Review architecture - Complete

### Phase 3: Present Suggestions

Combine operational and architectural improvements.

Categorize by type:
1. Workflow structure improvements
2. Agent coordination improvements
3. Error handling improvements
4. State management improvements
5. Architecture recommendations

Use AskUserQuestion:

```
Question: "Which categories would you like to address?"
Header: "Categories"
multiSelect: true
Options:
- Workflow (X issues) - Phase structure and flow
- Coordination (X issues) - Agent delegation
- Error Handling (X issues) - Recovery and fallbacks
- State Management (X issues) - Context and tracking
- Architecture (X suggestions) - Structural changes
```

### Phase 4: Select Improvements

For each selected category, present specific improvements:

```
Question: "Which [category] improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements in category]
```

Mark todo: Present suggestions - Complete

### Phase 5: Apply Changes

For each approved improvement:

1. Show the specific change (before/after)
2. Apply change using Edit tool
3. If creating new files, use Write tool
4. Confirm each change

For architectural changes that require restructuring:
1. Confirm with user before major changes
2. Create new files first
3. Update references
4. Remove old files if replaced

Mark todo: Apply improvements - Complete

### Phase 6: Validation

1. Re-read the modified orchestration
2. Verify all referenced agents exist
3. Check phase transitions are valid
4. Validate error handling
5. Check compact points present
6. Present summary of all changes

Mark todo: Validate changes - Complete

## Special Operations

### Adding Missing Phases

If analysis recommends adding phases:
1. Present proposed phase
2. Get user approval
3. Insert phase at correct position
4. Update data flow

### Refactoring Agents

If agent responsibilities need splitting:
1. Identify split boundaries
2. Create new agent file
3. Update orchestration references
4. Keep original for other uses

### Adding Error Handling

If error handling is missing:
1. Identify failure points
2. Propose error handling for each
3. Add approved handlers
4. Add recovery paths

## Error Handling

If orchestration not found:
- Suggest using Glob: `Glob pattern="**/commands/**/*.md"`

If analysis fails:
- Report partial results
- Suggest manual review

If edit fails:
- Report error
- Offer retry or skip
