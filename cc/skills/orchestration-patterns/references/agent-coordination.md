# Agent Coordination

Patterns for communication and coordination between agents in orchestrations.

## Agent Communication

### Task Tool Invocation

Invoke agents using the Task tool:

```markdown
Use Task tool with @agent-name:

prompt: |
  [Context from previous phase]

  Your task:
  [Specific instructions]

  Expected output:
  [Output format]
```

### Context Passing

Pass relevant context between agents:

```markdown
### Good Context Passing

Use Task tool with @implementer:

prompt: |
  ## Context from Design Phase

  Architecture: [summary, not full document]
  Key files: [list of files to modify]
  Constraints: [identified constraints]

  ## Your Task

  Implement the designed solution.
```

```markdown
### Bad Context Passing

Use Task tool with @implementer:

prompt: |
  [Dumps entire previous conversation]
  [Includes irrelevant details]
  [No clear task statement]
```

### Output Structuring

Structure agent outputs for downstream consumption:

```markdown
### Phase 1 Agent Output Format

## Summary
[1-2 sentence summary]

## Key Findings
1. [Finding 1]
2. [Finding 2]

## Files Identified
- path/to/file1.ts
- path/to/file2.ts

## Recommendations
1. [Recommendation 1]
2. [Recommendation 2]

## Data for Next Phase
[Structured data to pass forward]
```

## Handoff Patterns

### Explicit Handoff

Clear transfer of responsibility:

```markdown
## Phase 1 Complete

### Handoff to Phase 2

I have completed the analysis phase.

**For the next phase:**
- Identified 5 files requiring changes
- Found 3 integration points
- Detected 2 potential conflicts

**Phase 2 should:**
1. Review the identified files
2. Create implementation plan
3. Address potential conflicts
```

### Implicit Handoff

Coordinator manages transitions:

```markdown
### Coordinator Logic

1. Receive Phase 1 output
2. Extract relevant data for Phase 2
3. Construct Phase 2 prompt
4. Invoke Phase 2 agent
```

### Conditional Handoff

Transition based on conditions:

```markdown
### Gate Check

Phase 1 output indicates:
- Status: [SUCCESS / NEEDS_REVIEW / FAILED]

If SUCCESS:
  → Proceed to Phase 2
If NEEDS_REVIEW:
  → Ask user for decision
If FAILED:
  → Report error, offer retry
```

## Shared State

### Via TodoWrite

```markdown
### State in Todos

Todos track:
- Current phase
- Phase completion status
- Key data points

Example:
- [x] Phase 1: Discovery - Found 5 files
- [ ] Phase 2: Design - In progress
- [ ] Phase 3: Implementation
- [ ] Phase 4: Review
```

### Via Compact Points

```markdown
### After Phase 1

[COMPACT: Preserve for next phase:
- Files: src/auth.ts, src/user.ts, src/api.ts
- Pattern: Repository pattern
- Constraint: No breaking changes
]
```

### Via File State

For complex state, write to temporary file:

```markdown
### State File

Write to .claude/orchestration-state.json:
{
  "phase": 2,
  "discovery": {
    "files": ["..."],
    "patterns": ["..."]
  },
  "design": {
    "plan": "..."
  }
}
```

## Error Propagation

### Error Bubbling

Errors bubble up to coordinator:

```markdown
### Agent Error

Agent: @implementer
Error: "Cannot modify file: permission denied"

### Coordinator Handling

1. Log error with context
2. Determine if recoverable
3. If recoverable: Suggest fix, offer retry
4. If not: Report to user, offer alternatives
```

### Error Context

Include context for debugging:

```markdown
### Error Report

Phase: Implementation
Agent: @implementer
Action: Modifying src/auth.ts
Error: Permission denied
State at failure: [relevant state]

Possible causes:
1. File is read-only
2. Insufficient permissions
3. File is locked

Suggested actions:
1. Check file permissions
2. Close other editors
3. Run with elevated permissions
```

## Coordination Anti-Patterns

### Too Much Context

```markdown
### Problem

Passing entire conversation history to each agent.

### Solution

Extract and summarize relevant information.
Pass only what the agent needs.
```

### Unclear Responsibilities

```markdown
### Problem

Multiple agents with overlapping responsibilities.
Unclear who handles edge cases.

### Solution

Define clear boundaries.
Assign edge cases explicitly.
Use a decision matrix.
```

### No Error Handling

```markdown
### Problem

Assuming all agents succeed.
No recovery path for failures.

### Solution

Add error handling to each phase.
Define fallback behavior.
Report partial progress.
```

### Tight Coupling

```markdown
### Problem

Agents depend on specific output format of others.
Changes to one agent break others.

### Solution

Define stable interfaces.
Use versioned contracts.
Validate outputs before passing.
```
