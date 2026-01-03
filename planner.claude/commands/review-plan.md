---
description: Reviews plan files with multi-agent orchestration. Use for comprehensive plan quality analysis.
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <plan-path> [--goal <goal>] [--mode <quick|thorough>]
---

# /planner:review-plan

Reviews a plan file with multi-agent orchestration for comprehensive, multi-perspective analysis.

## Parameters Schema

```yaml
review-plan-arguments:
  type: object
  properties:
    plan_path:
      type: string
      description: Path to the plan file to review
    goal:
      type: string
      description: Optional goal for alignment checking
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [plan_path]
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

### 1. Load Plan

- [ ] Read: `{{plan_path}}`
- [ ] If not found: Prompt for correct path
- [ ] Extract: sections, milestones, dependencies, deliverables

### 2. Context Gathering

- [ ] If goal not provided: Extract from plan or ask user
- [ ] Search for related: requirements docs, existing issues

### 3. Analysis

**Thorough Mode - Parallel Analysis:**

Launch `planner-plan-reviewer`:
- Goal Alignment
- Completeness
- Feasibility
- Clarity
- Risk Coverage

Launch `planner-review-analyzer`:
- Required sections present
- Completeness percentage
- Best practices and anti-patterns
- Quality metrics (clarity, specificity, consistency)

**Adversarial Challenge** (`planner-review-challenger`):
- Challenge assumptions
- Identify blind spots
- Analyze failure modes
- Question estimates

**Synthesis** (`planner-review-synthesizer`):
- Deduplicate findings
- Resolve conflicts
- Prioritize by severity
- Generate recommendations

**Quick Mode:**
Single `planner-plan-reviewer` pass only.

### 4. Present Findings

```markdown
## Plan Review

**Overall Assessment**: {{score}}/5

### Quality Metrics
| Dimension | Score | Notes |
|-----------|-------|-------|
| Goal Alignment | X/5 | |
| Completeness | X% | |
| Feasibility | X/5 | |
| Clarity | X/5 | |
| Risk Coverage | X/5 | |

### Top Priority Issues
1. {{p0_issue_1}}

### Quick Wins
1. {{quick_win}}
```

### 5. Recommendations

```markdown
## Improvements

### Priority 0 - Critical
1. **{{issue}}**: Current → Suggested → Impact

### Quick Wins
1. {{quick_fix}}
```

## Usage Examples

```text
/planner:review-plan docs/planning/roadmap.md
/planner:review-plan project-plan.md --mode quick
/planner:review-plan docs/plan.md --goal "Launch MVP by Q2"
```

## Error Handling

- File not found: Suggest similar paths
- Plan too large: Summarize sections
- Goal unclear: Ask before evaluation
