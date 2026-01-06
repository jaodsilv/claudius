---
name: planner:analyzing-adversarially
description: >-
  Provides adversarial analysis methodology for challenging ideas and artifacts.
  Use when stress-testing assumptions, identifying failure modes, generating
  counter-arguments, or finding blind spots in plans and proposals.
---

# Analyzing Adversarially

Constructively critical analysis to identify weaknesses before they become failures.

## Analysis Components

| Component | Purpose | Key Questions |
|-----------|---------|---------------|
| Assumption Hunting | Find fragile premises | What must be true? What if opposite? |
| Failure Mode Analysis | Explore how it could fail | What triggers failure? What's probability/impact? |
| Counter-Arguments | Strongest opposing view | What would a skeptic say? |
| Stress Testing | Push to extremes | What at 10x scale? What if budget halved? |
| Logical Consistency | Find contradictions | Does solution conflict with itself? |

## Assumption Analysis

- **Explicit**: Stated assumptions - Are they valid? What if wrong?
- **Implicit**: Unstated premises - What's taken for granted?

Format per assumption:

```markdown
Assumption: [Statement]
Fragility: High/Medium/Low
Challenge: [Why might be wrong]
If Wrong: [Consequence]
```

## Failure Mode Categories

| Category | Description |
|----------|-------------|
| Complete Failure | Doesn't work at all |
| Partial Failure | Works with significant limitations |
| Scale Failure | Works small, fails at scale |
| Adoption Failure | Works technically, fails human factors |

## Stress Test Dimensions

| Dimension | Test Variations |
|-----------|-----------------|
| Scale | 10x/0.1x adoption rates |
| Resources | Budget/timeline/people constraints |
| Environment | Market/technology/competition changes |
| Edge Cases | Worst-case user behavior, adversarial scenarios |

## Counter-Argument Framework

1. **Steel-man the position**: Articulate strongest version of idea
2. **Identify the skeptic**: Who would oppose and why?
3. **Generate objections**: List specific, concrete concerns
4. **Rate severity**: Critical / Major / Minor
5. **Propose mitigations**: How could objection be addressed?

## Output Template

```markdown
## Adversarial Analysis: [Subject]

### Critical Assumptions
| Assumption | Fragility | Challenge | If Wrong |
|------------|-----------|-----------|----------|
| ... | High/Med/Low | ... | ... |

### Failure Modes
| Mode | Trigger | Probability | Impact | Mitigation |
|------|---------|-------------|--------|------------|
| ... | ... | High/Med/Low | High/Med/Low | ... |

### Counter-Arguments
1. **[Objection]** (Severity: Critical/Major/Minor)
   - Basis: [Why skeptic believes this]
   - Mitigation: [How to address]

### Stress Test Results
| Dimension | Scenario | Outcome | Risk Level |
|-----------|----------|---------|------------|
| ... | ... | ... | High/Med/Low |
```

## Best Practices

1. Be constructively critical - identify weaknesses WITH solutions
2. Be specific - "This fails because X" not "This might fail"
3. Prioritize by impact - catastrophic risks first
4. Challenge your own critique - avoid invalid objections
5. Separate fixable issues from fundamental flaws
