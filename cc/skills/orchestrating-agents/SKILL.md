---
name: cc:orchestrating-agents
description: >-
  Provides multi-agent orchestration patterns when designing complex workflows,
  coordinating multiple agents, or implementing phase-based command structures.
  Use when creating orchestrations or improving existing multi-agent workflows.
version: 1.0.0
---

# Orchestrating Agents

Guidelines for designing multi-agent orchestrations in Claude Code plugins.

## When to Use Orchestrations

Use orchestrations when a task requires:

1. Multiple specialized capabilities (different agents)
2. Distinct workflow phases
3. Complex error handling with recovery
4. User interaction at decision points

For simple linear tasks, prefer single commands or agents.

## Pattern Selection

| Pattern | Use Case |
|---------|----------|
| Sequential | Phases execute in order, each depends on previous |
| Parallel | Independent analyses that merge results |
| Iterative | Refinement loops with quality gates |
| Hierarchical | Coordinator manages sub-coordinators |

## Orchestration Command Structure

```markdown
---
description: [Brief workflow description]
argument-hint: [Arguments]
allowed-tools: ["Task", "TodoWrite", "AskUserQuestion", "Read", ...]
---

# Orchestration: [Name]

## Phase 1: [Name]

### Purpose
[What this phase accomplishes]

### Execution
Use Task tool with @[agent-name]:
  [Detailed instructions]

### Gate
[Condition to proceed]

[COMPACT: preserve key outputs]

## Phase 2: [Name]
...
```

## Phase Definition Checklist

Each phase requires:

- [ ] Purpose: Clear description of what phase accomplishes
- [ ] Agent: Which agent handles this phase
- [ ] Inputs: What data/context this phase receives
- [ ] Outputs: What this phase produces
- [ ] Gate: Conditions that must pass to proceed
- [ ] Error handling: What happens if phase fails

## Data Flow Guidelines

1. Pass summaries, not raw content between phases
2. Use compact points to preserve essential state
3. Track progress with TodoWrite
4. Define explicit handoffs between agents

## Complexity Assessment

| Factor | Simple | Moderate | Complex |
|--------|--------|----------|---------|
| Phases | 1-2 | 3-4 | 5+ |
| Agents | 1-2 | 3-4 | 5+ |
| User interactions | 0-1 | 2-3 | 4+ |

If complexity exceeds "Moderate", consider decomposition.

## Additional Resources

- **`references/coordinator-patterns.md`** - Detailed coordination patterns
- **`references/agent-coordination.md`** - Agent communication patterns
- **`references/complexity-assessment.md`** - Complexity scoring guidelines
