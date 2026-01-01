---
description: Reviews requirements quality with multi-agent orchestration. Use for validating completeness and testability.
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--requirements-path <path>] [--mode <quick|thorough>]
---

# /planner:review-requirements

Reviews requirements document with multi-agent orchestration for quality, completeness, and testability.

## Parameters Schema

```yaml
review-requirements-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to roadmap file
    requirements_path:
      type: string
      default: "docs/planning/requirements.md"
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
  required: [context]
```

## Orchestration Pattern

```text
Thorough Mode:
Phase 1: Parallel → planner-requirements-reviewer + planner-review-analyzer
Phase 2: Challenge → planner-review-challenger
Phase 3: Synthesize → planner-review-synthesizer
Phase 4: Interactive → Refine with user feedback

Quick Mode: Single agent (planner-requirements-reviewer)
```

## Workflow

### 1. Load Documents

- [ ] Load requirements: `Read: {{requirements_path}}`
- [ ] If `$context` is file path: Load as roadmap
- [ ] Otherwise: Use as goal string
- [ ] Parse: functional requirements, NFRs, constraints, assumptions

### 2. Analysis

**Thorough Mode - Parallel Analysis:**

Launch `planner-requirements-reviewer`:
Per requirement, evaluate SMART criteria:
- Specific: Single interpretation?
- Measurable: Quantifiable?
- Achievable: Realistic?
- Relevant: Aligned with goal?
- Time-bound: Scoped?

Quality attributes: Atomic, Traceable, Testable, Consistent

Launch `planner-review-analyzer`:
- Functional requirements present and categorized?
- Non-functional requirements present?
- Constraints documented?
- Acceptance criteria for each?
- Priority assigned?

**Adversarial Challenge** (`planner-review-challenger`):
- Missing requirements (security, performance, accessibility)?
- Conflicting requirements?
- Unrealistic requirements?
- Vague requirements?
- Edge cases not considered?
- Testability gaps?

**Synthesis** (`planner-review-synthesizer`):
- Quality scores per dimension
- Gap analysis
- Suggested rewrites
- Missing requirements to add

**Quick Mode:**
Single `planner-requirements-reviewer` pass only.

### 3. Present Findings

```markdown
## Requirements Review

**Document**: {{requirements_path}}

### Quality Summary
| Dimension | Score |
|-----------|-------|
| Clarity | X/5 |
| Completeness | X% |
| Testability | X/5 |
| Consistency | X/5 |

### Requirements with Issues

#### FR-003: "System should be fast"
**Issues**: Not specific, not measurable, not testable
**Suggested Rewrite**: "API endpoints shall respond within 200ms for 95% of requests under 1000 concurrent users."

### Gap Analysis
1. **Security**: No authentication requirements
   - Draft: "System shall authenticate users via..."
```

### 4. Interactive Refinement

For each critical issue:
1. Present the problem
2. Use AskUserQuestion for clarification
3. Propose improved wording
4. Note resolution

### 5. Final Report

```markdown
## Requirements Review Report

**Quality**: {{before}} → {{after}}
**Issues Found**: {{count}}
**Issues Resolved**: {{resolved}}

### Changes Made
| ID | Original | Updated |
|----|----------|---------|

### Remaining Issues
1. {{remaining}}

### Next Steps
1. Validate with stakeholders
2. Create test cases from requirements
```

## Usage Examples

```text
/planner:review-requirements "Launch MVP by Q2"
/planner:review-requirements docs/roadmap.md --mode quick
/planner:review-requirements "API v2" --requirements-path docs/api-v2/requirements.md
```

## Error Handling

- Requirements not found: Suggest `/planner:gather-requirements`
- User unresponsive: Save progress, allow resume
- Agent timeout: Report partial results
