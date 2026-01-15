---

description: Reviews architecture decisions with multi-agent orchestration. Use for validating technical designs against goals.
allowed-tools: Task, Read, Glob, Grep, WebSearch, AskUserQuestion, TodoWrite
argument-hint: <goal|requirements-path> [--architecture-path <path>] [--mode <quick|thorough>]
---

# /planner:review-architecture

Reviews architecture decisions with multi-agent orchestration for alignment with goals and requirements.

## Parameters Schema

```yaml
review-architecture-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to requirements file
    architecture_path:
      type: string
      description: Path to architecture documentation
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [context]
```

## Orchestration Pattern

```text
Thorough Mode:
Phase 1: Parallel → planner-architecture-reviewer + planner-review-analyzer
Phase 2: Challenge → planner-review-challenger
Phase 3: Synthesize → planner-review-synthesizer
Phase 4: Interactive → Present findings, gather feedback

Quick Mode: Single agent (planner-architecture-reviewer)
```

## Workflow

### 1. Load Context

- [ ] Initialize TodoWrite with phases
- [ ] If `$context` is file path: Load as requirements
- [ ] Otherwise: Use as goal string

### 2. Find Architecture Docs

- [ ] If `$architecture_path` provided: Read file
- [ ] If not: `Glob: **/architecture*.md, **/design*.md, **/adr/*.md`
- [ ] If multiple found: Ask user to select
- [ ] Extract: components, data flows, technologies, decisions

### 3. Analysis

**Thorough Mode - Parallel Analysis:**

Launch `planner-architecture-reviewer`:
- Goal alignment
- Requirements coverage (Performance, Security, Scalability, Reliability)
- Technical soundness
- Patterns and anti-patterns

Launch `planner-review-analyzer`:
- Components defined?
- Data flows described?
- Trade-offs documented?
- Security considerations?

**Adversarial Challenge** (`planner-review-challenger`):
- Scale failure modes
- Security vulnerabilities
- Technology risks
- Complexity debt
- Missing components

**Synthesis** (`planner-review-synthesizer`):
- Overall score
- Prioritized concerns
- Alternative recommendations

**Quick Mode:**
Single `planner-architecture-reviewer` pass only.

### 4. Present Findings

```markdown
## Architecture Review

**Context**: {{goal_or_requirements}}
**Overall Score**: {{score}}/5

### Goal Alignment
| Aspect | Support | Gap |
|--------|---------|-----|

### Dimension Scores
| Dimension | Score | Finding |
|-----------|-------|---------|
| Goal Alignment | X/5 | |
| Technical Soundness | X/5 | |
| Maintainability | X/5 | |
| Scalability | X/5 | |
| Security | X/5 | |

### Patterns
- Good: {{patterns}}
- Concerns: {{anti_patterns}}
```

### 5. Recommendations

```markdown
## Recommendations

### High Priority
1. **{{concern}}**: Current → Suggested → Trade-off

### Alternative Approaches
- {{alternatives}}
```

## Usage Examples

```text
/planner:review-architecture "Build scalable notification system"
/planner:review-architecture "API v2" --mode quick
/planner:review-architecture docs/requirements.md --architecture-path docs/arch.md
```

## Error Handling

- Context not provided: Prompt user
- Architecture not found: Search with Glob, present options
- Agent timeout: Report partial results
