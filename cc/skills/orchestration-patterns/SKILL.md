---
name: Orchestration Patterns
description: >-
  This skill should be used when designing "orchestration architectures",
  "multi-agent workflows", "agent coordination", "workflow patterns",
  "phase-based workflows", "coordinator patterns", or implementing complex
  multi-agent orchestrations in Claude Code plugins.
version: 1.0.0
---

# Orchestration Patterns for Claude Code

Patterns for designing and implementing multi-agent orchestrations that coordinate specialized agents to complete complex workflows.

## What is an Orchestration?

An orchestration is a command that coordinates multiple agents to complete complex workflows.
Unlike simple commands that execute directly, orchestrations delegate work to specialized
agents and manage the overall workflow.

## When to Use Orchestrations

Use orchestrations when:

1. Task requires multiple specialized capabilities
2. Workflow has distinct phases
3. Different agents handle different aspects
4. Complex error handling is needed
5. User interaction is required at decision points

## Core Coordination Patterns

### Sequential Pattern

Agents execute in order, each depending on the previous.

```text
Phase 1 (Agent A) → Phase 2 (Agent B) → Phase 3 (Agent C)
```

Best for: Linear workflows with dependencies, pipelines, step-by-step processes.

### Parallel Pattern

Independent agents execute concurrently.

```text
        → Agent A →
Start →             → Merge
        → Agent B →
```

Best for: Independent analysis from multiple perspectives, gathering diverse input.

### Iterative Pattern

Phases may loop back based on conditions.

```text
Design → Implement → Review → [Loop if needed]
```

Best for: Refinement workflows, design-implement-review cycles, quality gates.

### Hierarchical Pattern

Coordinator manages sub-coordinators.

```text
Main Coordinator
├── Analysis Coordinator
│   ├── Agent A1
│   └── Agent A2
└── Implementation Coordinator
    ├── Agent B1
    └── Agent B2
```

Best for: Complex workflows with sub-workflows, domain separation.

## Orchestration Components

### Phase Definition

Each phase requires:

1. **Purpose**: Clear description of what this phase accomplishes
2. **Agent**: Which agent handles this phase
3. **Inputs**: What data/context this phase receives
4. **Outputs**: What this phase produces for downstream
5. **Gates**: Conditions that must pass to proceed
6. **Error Handling**: What happens if this phase fails

### Data Flow

Define what passes between phases:

```markdown
Phase 1 Output → Phase 2 Input
- Analysis results
- Identified issues
- Recommendations
```

### State Management

Track progress across phases:

1. Use TodoWrite for phase tracking
2. Add compact points after each phase
3. Preserve essential state across compacts
4. Define what state each phase needs

### Gate Conditions

Checkpoints that must pass before proceeding:

- Test results (all tests pass)
- Review approval (design approved)
- User confirmation (proceed with changes)
- Validation (output meets criteria)

## Implementation Structure

### Orchestration Command Structure

```markdown
---
description: Review code changes with multiple specialized agents
argument-hint: <pr-number|file-path>
allowed-tools: ["Task", "TodoWrite", "AskUserQuestion", "Read", "Glob"]
---

# Orchestration: Code Review

## Phase 1: Discovery

### Purpose
Identify files to review and gather context about changes.

### Execution
Use Task tool with @code-explorer agent:
  Analyze the changes in [target].
  Identify affected files, dependencies, and test coverage.
  Return a structured summary of what needs review.

### Gate
Discovery complete with file list

[COMPACT: preserve file list and change summary]

## Phase 2: Analysis

### Purpose
Deep analysis of code quality, security, and patterns.

### Execution
Use Task tool with @code-reviewer agent:
  Review the following files: [file list from Phase 1]
  Check for: bugs, security issues, style violations
  Return categorized findings by severity.

### Gate
Analysis complete with findings

## Phase 3: Report
...
```

## Additional Resources

For detailed patterns, consult:

- **`references/coordinator-patterns.md`** - Detailed coordination patterns
- **`references/agent-coordination.md`** - Agent communication patterns
- **`references/complexity-assessment.md`** - Assessing orchestration complexity
