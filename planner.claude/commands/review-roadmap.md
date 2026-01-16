---

description: Reviews roadmaps with multi-agent orchestration against a goal. Use for validating roadmap alignment.
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <goal> [--roadmap-path <path>] [--mode <quick|thorough>]
---

# /planner:review-roadmap

Reviews a roadmap with multi-agent orchestration for alignment with a goal and overall quality.

## Parameters Schema

```yaml
review-roadmap-arguments:
  type: object
  properties:
    goal:
      type: string
      description: Goal to evaluate roadmap against
    roadmap_path:
      type: string
      default: "docs/planning/roadmap.md"
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [goal]
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

### 1. Load Roadmap

- [ ] Read: `{{roadmap_path}}`
- [ ] If not found: `Glob: **/roadmap*.md`
- [ ] Extract: phases, milestones, dependencies, risks

### 2. Goal Alignment Check

- [ ] Each phase contributes to goal?
- [ ] Milestones represent progress toward goal?
- [ ] Will completing roadmap achieve goal?
- [ ] What gaps exist?

### 3. Analysis

**Thorough Mode - Parallel Analysis:**

Launch `planner-plan-reviewer` (roadmap mode):
- Phase sequencing (logical order?)
- Dependencies (correctly mapped?)
- Milestones (SMART criteria met?)
- Timeline (realistic?)
- Risk coverage

Launch `planner-review-analyzer`:
- Goal statement present?
- Phases with clear boundaries?
- Milestones with success criteria?
- Deliverables per phase?
- Dependencies mapped?

**Adversarial Challenge** (`planner-review-challenger`):
- Timeline assumptions optimistic?
- Dependency risks (what if X delayed?)
- Phase sequencing risks
- Missing phases
- Resource assumptions realistic?

**Synthesis** (`planner-review-synthesizer`):
- Goal alignment score
- Prioritized issues
- Timeline adjustments
- Risk mitigations

**Quick Mode:**
Single `planner-plan-reviewer` pass only.

### 4. Present Findings

```markdown
## Roadmap Review: {{goal}}

**Alignment Score**: {{score}}/5

### Goal Alignment
| Phase | Alignment | Contribution | Issue |
|-------|-----------|--------------|-------|

### Milestone Quality
| Milestone | SMART Score | Issue |
|-----------|-------------|-------|

### Key Challenges
- {{timeline_risk}}
- {{dependency_risk}}
```

### 5. Recommendations

```markdown
## Recommendations

### Alignment Fixes
1. **Strengthen Phase 2**: Add milestone {{milestone}}

### Structural Improvements
1. **Reorder Phase 3 and 4**: {{reason}}

### Missing Elements
1. Risk mitigation for {{risk}}
2. Buffer time in Phase {{n}}
```

## Usage Examples

```text
/planner:review-roadmap "Implement user authentication by Q2"
/planner:review-roadmap "Launch mobile app" --mode quick
/planner:review-roadmap "Scale to 1M users" --roadmap-path docs/scaling-roadmap.md
```

## Error Handling

- Goal not provided: Prompt user
- Roadmap not found: Search with Glob, present options
- Empty roadmap: Report no content to review
