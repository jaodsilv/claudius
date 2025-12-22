# Complexity Assessment

Guidelines for assessing orchestration complexity and choosing appropriate patterns.

## Complexity Factors

### Factor 1: Phase Count

| Phases | Complexity | Notes |
|--------|------------|-------|
| 1-2 | Simple | Consider if orchestration is needed |
| 3-4 | Moderate | Standard orchestration |
| 5-7 | Complex | Consider hierarchical pattern |
| 8+ | Very Complex | Likely needs decomposition |

### Factor 2: Agent Count

| Agents | Complexity | Notes |
|--------|------------|-------|
| 1-2 | Simple | May not need orchestration |
| 3-4 | Moderate | Standard coordination |
| 5-7 | Complex | Consider sub-coordinators |
| 8+ | Very Complex | Hierarchical required |

### Factor 3: Data Dependencies

| Type | Complexity | Description |
|------|------------|-------------|
| Linear | Simple | Each phase depends only on previous |
| Fork-Join | Moderate | Parallel then merge |
| Cross-Phase | Complex | Multiple dependencies |
| Circular | Very Complex | Iterative with cross-references |

### Factor 4: User Interaction

| Interaction Points | Complexity | Notes |
|-------------------|------------|-------|
| 0-1 | Simple | Mostly automated |
| 2-3 | Moderate | Key decision points |
| 4+ | Complex | Heavy user involvement |

### Factor 5: Error Scenarios

| Error Handling | Complexity | Description |
|----------------|------------|-------------|
| Fail-fast | Simple | Stop on any error |
| Retry | Moderate | Attempt recovery |
| Partial | Complex | Continue with available results |
| Recovery | Very Complex | State restoration required |

## Complexity Score

Calculate overall complexity:

```
Score = Phases × 1 + Agents × 1.5 + Dependencies × 2 + Interactions × 1 + Errors × 1.5

Simple: Score < 10
Moderate: Score 10-20
Complex: Score 20-35
Very Complex: Score > 35
```

## Pattern Selection by Complexity

### Simple (Score < 10)

Recommended pattern: **Sequential**

```markdown
Phase 1 → Phase 2 → Done
```

Characteristics:
- 2-3 phases
- 1-2 agents
- Linear data flow
- Minimal error handling

### Moderate (Score 10-20)

Recommended pattern: **Sequential or Fork-Join**

```markdown
Sequential:
Phase 1 → Phase 2 → Phase 3 → Done

Fork-Join:
Start → [A, B] → Merge → Done
```

Characteristics:
- 3-4 phases
- 2-4 agents
- Some parallelization
- Basic error handling

### Complex (Score 20-35)

Recommended pattern: **Hierarchical or Iterative**

```markdown
Hierarchical:
Main
├── Sub-A → [A1, A2]
└── Sub-B → [B1, B2]

Iterative:
Design → Implement → Review → [Loop]
```

Characteristics:
- 5-7 phases
- 4-6 agents
- Complex dependencies
- User interaction points
- Recovery handling

### Very Complex (Score > 35)

Recommended pattern: **Decomposition Required**

Split into multiple orchestrations:

```markdown
Master Orchestration
├── Orchestration A
├── Orchestration B
└── Orchestration C
```

Consider:
- Breaking into smaller orchestrations
- Using state machine pattern
- Adding extensive logging
- Implementing checkpoints

## Simplification Strategies

### Reduce Phase Count

```markdown
Before (5 phases):
Discover → Analyze → Plan → Implement → Review

After (3 phases):
Discover+Analyze → Plan+Implement → Review
```

### Combine Agents

```markdown
Before (4 agents):
@security-reviewer
@performance-reviewer
@style-reviewer
@general-reviewer

After (2 agents):
@code-reviewer (covers security, style)
@performance-reviewer
```

### Linearize Dependencies

```markdown
Before (cross-dependencies):
A ↔ B
↓   ↓
C ↔ D

After (linear):
A → B → C → D
```

### Reduce Interaction Points

```markdown
Before (4 interactions):
- Approve discovery results
- Approve design
- Approve implementation
- Approve review

After (2 interactions):
- Approve plan (after discovery+design)
- Approve changes (after implementation+review)
```

## Complexity Warning Signs

### Red Flags

1. **More than 7 phases**: Decomposition needed
2. **Agents duplicating work**: Responsibility overlap
3. **Circular dependencies**: Infinite loop risk
4. **No clear success criteria**: Unclear when done
5. **Every phase needs user input**: Over-engineered

### Questions to Ask

1. Can this be done without orchestration?
2. Can phases be combined?
3. Can agents be consolidated?
4. Are all interactions necessary?
5. What's the minimum viable orchestration?

## Documentation Requirements by Complexity

| Complexity | Required Documentation |
|------------|------------------------|
| Simple | Phase list, agent list |
| Moderate | + Data flow, error handling |
| Complex | + State diagram, recovery procedures |
| Very Complex | + Design document, testing strategy |
