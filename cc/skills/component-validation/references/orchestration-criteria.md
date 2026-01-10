# Orchestration Validation Criteria

Detailed validation rules for Claude Code orchestration commands.

## Structure Validation

### Required Sections

| Section | Purpose | Severity if Missing |
|---------|---------|---------------------|
| Phase definitions | Clear phase structure | CRITICAL |
| Data flow | Information passing between phases | HIGH |
| Error handling | Recovery and fallback patterns | HIGH |

## Phase Validation

### Phase Structure

Each phase should have:

| Element | Requirement | Severity |
|---------|-------------|----------|
| Purpose | Clear description of phase goal | HIGH |
| Execution | Specific actions to perform | CRITICAL |
| Gate/Validation | Conditions to proceed to next phase | HIGH |
| Error handling | What to do if phase fails | MEDIUM |

### Phase Naming

| Convention | Example | Severity |
|------------|---------|----------|
| Numbered | Phase 1, Phase 2 | - |
| Named | Discovery, Analysis, Application | - |
| Mixed | Phase 1: Discovery | RECOMMENDED |

## Data Flow Validation

### Input Handling

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| Input parsing | Arguments parsed explicitly | HIGH |
| Validation | Inputs validated before use | MEDIUM |
| Defaults | Sensible defaults for optional inputs | LOW |

### Inter-Phase Communication

| Pattern | Description | Severity if Missing |
|---------|-------------|---------------------|
| State preservation | TodoWrite for progress tracking | MEDIUM |
| Context passing | Explicit data handoff between phases | HIGH |
| Intermediate results | Store for later phases | MEDIUM |

## Agent Coordination

### Delegation Patterns

| Pattern | When to Use | Severity if Wrong |
|---------|-------------|-------------------|
| Sequential | Phases depend on previous results | - |
| Parallel | Independent analyses | MEDIUM (if not used when possible) |
| Hierarchical | Coordinator → Sub-agents | - |

### Agent Communication

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| Clear prompts | Specific task description for each agent | HIGH |
| Context provision | Necessary context passed to agents | HIGH |
| Result handling | Agent outputs properly processed | HIGH |

## Error Handling Validation

### Required Patterns

| Pattern | Requirement | Severity if Missing |
|---------|-------------|---------------------|
| Phase failure | What to do if a phase fails | HIGH |
| Agent failure | Recovery if delegated agent fails | HIGH |
| Partial completion | Handle partial success | MEDIUM |
| User notification | Inform user of errors | HIGH |

### Recovery Strategies

| Strategy | When to Use |
|----------|-------------|
| Retry | Transient failures |
| Skip | Non-critical phase |
| Fallback | Alternative approach available |
| Abort | Critical failure, cannot proceed |

## Quality Criteria

### CRITICAL Issues

Must fix immediately:

- Missing phase structure
- No clear phase transitions
- Broken agent delegation
- Missing critical error handling

### HIGH Issues

Should fix for quality:

- Phases without gates/validation
- Missing data flow between phases
- No TodoWrite progress tracking
- Vague agent task descriptions
- Missing error recovery

### MEDIUM Issues

Consider fixing for improvement:

- Sequential when parallel possible
- Missing intermediate result storage
- Incomplete phase descriptions
- No context management strategy

### LOW Issues

Nice to have polish:

- Phase naming consistency
- Additional validation steps
- Format improvements
- Documentation enhancements

## Complexity Assessment

### When to Use Orchestration

| Scenario | Recommendation |
|----------|----------------|
| Single-step task | Simple command, not orchestration |
| 2-3 sequential steps | Simple command may suffice |
| 4+ phases | Orchestration appropriate |
| Parallel execution needed | Orchestration required |
| Multiple agent types | Orchestration required |

### Pattern Selection

| Pattern | Use When |
|---------|----------|
| Sequential | Each phase depends on previous |
| Parallel | Independent analyses can run together |
| Iterative | Refinement cycles needed |
| Hierarchical | Complex multi-agent coordination |

## Example Phase Structure

```markdown
### Phase 1: Discovery

**Purpose**: Identify all components to analyze

**Execution**:
1. Use Glob to find all command files
2. Use Glob to find all agent files
3. Create TodoWrite with component list

**Gate**: At least one component found

**Error**: If no components, report "No components found in plugin"
```
