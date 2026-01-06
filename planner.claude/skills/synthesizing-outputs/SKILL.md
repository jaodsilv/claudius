---
name: planner:synthesizing-outputs
description: >-
  Provides multi-source synthesis methodology for merging findings from multiple
  agents. Use when combining review findings, ideation outputs, or other
  multi-perspective analyses into unified, prioritized recommendations.
---

# Synthesizing Outputs

Merge findings from multiple agents into unified, prioritized recommendations.

## Synthesis Process

1. **Inventory**: Create master list of all findings with source attribution
2. **Deduplicate**: Merge overlapping findings (same issue, different words)
3. **Resolve Conflicts**: When sources disagree, decide with rationale
4. **Categorize**: Group as convergent/complementary/divergent
5. **Prioritize**: Weight by severity, frequency, fixability, impact
6. **Recommend**: Generate actionable next steps

## Deduplication Rules

- Same issue from multiple sources: Combine, note all sources, take highest severity
- Complementary findings: Group together, create unified recommendation
- Preserve nuance when perspectives add distinct value

## Conflict Resolution Principles

| Conflict Type | Resolution |
|---------------|------------|
| Risk assessment | Conservative view wins |
| Goal alignment | Domain expert wins |
| Structural issues | Systematic analysis wins |
| Uncertain | Highest severity wins |

## Priority Matrix

| Priority | Criteria |
|----------|----------|
| P0 | Critical + 2+ sources, or blocks usage |
| P1 | High + multiple sources, or Critical single |
| P2 | Medium + multiple sources, or High single |
| P3 | Medium single, or Low multiple |
| P4 | Low single |

## Recommendation Format

```markdown
### [Issue Title]
**Priority**: P0/P1/P2/P3/P4
**Sources**: [Who found it]
**Issue**: [Description]
**Why It Matters**: [Impact]
**Recommendation**: [Action]
**Effort**: Low/Medium/High
```

## Executive Summary Essentials

- Overall quality assessment
- Top 3-5 issues requiring attention
- Quick wins (low effort, high impact)
- Major effort items
- Recommended next steps

## Guidelines

1. **Be integrative**: Find connections between findings
2. **Be decisive**: Resolve conflicts, don't just list them
3. **Focus on action**: Every finding needs a recommendation
4. **Highlight quick wins**: Build momentum with low effort, high impact items
