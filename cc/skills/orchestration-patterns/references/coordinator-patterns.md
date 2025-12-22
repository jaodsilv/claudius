# Coordinator Patterns

Detailed patterns for orchestration coordinators.

## Sequential Coordinator

Executes phases in strict order with data passing between them.

### Structure

```markdown
## Phase 1: Discovery
Agent: @explorer
Input: User request
Output: Codebase understanding, identified files

## Phase 2: Design
Agent: @architect
Input: Phase 1 output (codebase understanding)
Output: Implementation plan

## Phase 3: Implementation
Agent: @implementer
Input: Phase 2 output (implementation plan)
Output: Code changes

## Phase 4: Review
Agent: @reviewer
Input: Phase 3 output (code changes)
Output: Review feedback, approval status
```

### Data Passing

```markdown
### Phase Transition: 1 → 2

Pass to Phase 2:
- Identified files list
- Codebase patterns found
- Constraints discovered

Do NOT pass:
- Raw file contents (too large)
- Exploration steps (irrelevant)
```

### Error Handling

```markdown
If Phase X fails:
1. Log failure reason
2. Ask user: Retry / Skip / Abort
3. If retry: Re-execute phase
4. If skip: Mark as incomplete, continue
5. If abort: Report partial progress
```

## Fork-Join Coordinator

Executes parallel phases then merges results.

### Structure

```markdown
## Phase 1: Fork

Launch in parallel:

### Thread A: Security Analysis
Agent: @security-reviewer
Focus: Security vulnerabilities

### Thread B: Performance Analysis
Agent: @performance-reviewer
Focus: Performance issues

### Thread C: Style Analysis
Agent: @style-reviewer
Focus: Code style issues

## Phase 2: Join

Merge results from all threads:
- Combine all issues found
- Deduplicate overlapping issues
- Prioritize by severity
```

### Merge Strategy

```markdown
### Merge Rules

1. Combine all issues into single list
2. Deduplicate by location + type
3. For conflicts: Keep higher severity
4. Sort by severity, then by location
```

### Handling Partial Completion

```markdown
If Thread X fails but others succeed:
1. Continue with available results
2. Note incomplete analysis in summary
3. Offer to retry failed thread
```

## Iterative Coordinator

Loops through phases until condition is met.

### Structure

```markdown
## Iteration Loop

### Phase A: Generate
Agent: @generator
Output: Draft content

### Phase B: Review
Agent: @reviewer
Output: Feedback, approval status

### Gate: Review Passed?
- If yes: Exit loop, proceed to finalization
- If no: Return to Phase A with feedback
- Max iterations: 3

## Post-Loop: Finalize
Agent: @finalizer
Input: Approved content
Output: Final deliverable
```

### Loop Control

```markdown
### Loop Variables

iteration_count = 0
max_iterations = 3
approved = false

### Loop Logic

while not approved and iteration_count < max_iterations:
    result = execute_phase_a(feedback)
    approved, feedback = execute_phase_b(result)
    iteration_count += 1

if not approved:
    ask_user: "Max iterations reached. Accept current result?"
```

## Hierarchical Coordinator

Delegates to sub-coordinators for complex workflows.

### Structure

```markdown
## Main Coordinator

### Sub-Coordinator 1: Analysis Phase
Manages: @discovery-agent, @analysis-agent
Output: Comprehensive analysis

### Sub-Coordinator 2: Implementation Phase
Manages: @planner-agent, @implementer-agent
Input: Analysis from Sub-Coordinator 1
Output: Implemented changes

### Sub-Coordinator 3: Validation Phase
Manages: @tester-agent, @reviewer-agent
Input: Changes from Sub-Coordinator 2
Output: Validation results
```

### Sub-Coordinator Interface

```markdown
### Sub-Coordinator Contract

Input: Defined input schema
Output: Defined output schema
State: Managed internally
Errors: Bubbled up with context
```

## State Machine Coordinator

Explicit state transitions based on conditions.

### Structure

```markdown
## States

- INITIAL: Starting state
- ANALYZING: Running analysis
- WAITING_APPROVAL: Awaiting user decision
- IMPLEMENTING: Applying changes
- VALIDATING: Checking results
- COMPLETE: Finished successfully
- FAILED: Finished with error

## Transitions

INITIAL → ANALYZING: Always
ANALYZING → WAITING_APPROVAL: Analysis complete
WAITING_APPROVAL → IMPLEMENTING: User approved
WAITING_APPROVAL → COMPLETE: User declined
IMPLEMENTING → VALIDATING: Changes applied
VALIDATING → COMPLETE: Validation passed
VALIDATING → IMPLEMENTING: Validation failed (retry)
Any → FAILED: Unrecoverable error
```

### State Persistence

```markdown
### State Storage

Use TodoWrite to track:
- Current state
- State history
- State-specific data

### State Recovery

On resume:
1. Read current state from todos
2. Determine valid transitions
3. Continue from current state
```

## Choosing a Pattern

| Scenario | Recommended Pattern |
|----------|---------------------|
| Linear workflow, clear dependencies | Sequential |
| Independent parallel analysis | Fork-Join |
| Quality refinement loops | Iterative |
| Complex multi-domain workflow | Hierarchical |
| Complex conditional logic | State Machine |
| Simple 2-3 phase workflow | Sequential |
