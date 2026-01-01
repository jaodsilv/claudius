---
description: Reviews prioritization alignment with multi-agent orchestration. Use for validating issue rankings against goals.
allowed-tools: Task, Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--prioritization-path <path>] [--mode <quick|thorough>]
---

# /planner:review-prioritization

Reviews issue prioritization with multi-agent orchestration for alignment with a goal or roadmap.

## Parameters Schema

```yaml
review-prioritization-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to roadmap file
    prioritization_path:
      type: string
      default: "docs/planning/prioritization.md"
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [context]
```

## Orchestration Pattern

```text
Thorough Mode:
Phase 1: Parallel → planner-plan-reviewer + planner-review-analyzer
Phase 2: Challenge → planner-review-challenger
Phase 3: Synthesize → planner-review-synthesizer
Phase 4: Interactive → Present findings, gather feedback

Quick Mode: Single agent (planner-plan-reviewer)
```

## Workflow

### 1. Load Artifacts

- [ ] Load prioritization: `Read: {{prioritization_path}}`
- [ ] If `$context` is file path: Load as roadmap
- [ ] Otherwise: Use as goal string
- [ ] Extract: phases, milestones, key deliverables

### 2. Analysis

**Thorough Mode - Parallel Analysis:**

Launch `planner-plan-reviewer`:
- Priority alignment (P0/P1 items align with goal?)
- Coverage (all goal aspects covered?)
- Sequencing (priorities respect dependencies?)
- Gaps (goal areas with no issues?)
- Mismatches (high priority items that don't contribute?)

Launch `planner-review-analyzer`:
- Framework consistently applied?
- All items have scores/rationale?
- Dependencies documented?
- Effort estimates present?

**Adversarial Challenge** (`planner-review-challenger`):
- Over-prioritized items (should P0s be P1s?)
- Under-prioritized items (critical items buried?)
- Missing issues
- Bias detection
- Dependency risks

**Synthesis** (`planner-review-synthesizer`):
- Alignment score
- Priority adjustment recommendations
- Coverage gaps
- Quick wins

**Quick Mode:**
Single `planner-plan-reviewer` pass only.

### 3. Present Findings

```markdown
## Prioritization Alignment Review

**Context**: {{goal_or_roadmap}}
**Alignment Score**: {{score}}/5

### Alignment by Priority

#### P0 - Critical
| Issue | Title | Alignment | Notes |
|-------|-------|-----------|-------|

#### P1 - High
...

### Coverage Analysis
| Goal Aspect | Covered By | Priority |
|-------------|------------|----------|

### Quick Wins
1. {{quick_win}}
```

### 4. Recommendations

```markdown
## Priority Adjustments

### Raise Priority
1. **#127 → P0**: Directly blocks Phase 1 milestone

### Lower Priority
1. **#124 → P2**: Not goal-critical

### Create New Issues
1. **{{missing_area}}**: Suggested priority P1

### Label Commands
```bash
gh issue edit 127 --add-label "P0" --remove-label "P1"
```
```

## Usage Examples

```text
/planner:review-prioritization "Ship MVP by end of month"
/planner:review-prioritization docs/roadmap.md --mode quick
/planner:review-prioritization "API v2" --prioritization-path docs/api-v2/priorities.md
```

## Error Handling

- Context not provided: Prompt user
- Prioritization file not found: Search with Glob, present options
- Agent timeout: Report partial results
