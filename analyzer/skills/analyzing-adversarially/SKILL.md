---
description: >-
  Provides adversarial analysis methodology for challenging any input —
  analyses, review comments, proposals, code changes, or requests.
  Use when stress-testing assumptions, identifying blind spots, or
  finding weaknesses before acting on analytical output.
user-invocable: false
model: sonnet
---

# Analyzing Adversarially

Constructively critical analysis to identify weaknesses before they become failures.

## Analysis Components

| Component | Purpose | Key Questions |
| :-------- | :------ | :------------ |
| Assumption Hunting | Find fragile premises | What must be true? What if opposite? |
| Failure Mode Analysis | Explore how it could fail | What triggers failure? What's probability/impact? |
| Counter-Arguments | Strongest opposing view | What would a skeptic say? |
| Stress Testing | Push to extremes | What at 10x scale? What if budget halved? |
| Logical Consistency | Find contradictions | Does the input conflict with itself? |

## Assumption Analysis

- **Explicit**: Stated assumptions — Are they valid? What if wrong?
- **Implicit**: Unstated premises — What's taken for granted?

Format per assumption:

```markdown
Assumption: [Statement]
Fragility: High/Medium/Low
Challenge: [Why might be wrong]
If Wrong: [Consequence]
```

## Failure Mode Categories

| Category | Description |
| :------- | :---------- |
| Complete Failure | Analysis/proposal is entirely wrong |
| Partial Failure | Correct in some areas, wrong in others |
| Missing Context | Correct given available data, but key data is missing |
| Scope Failure | Correct for narrow scope, fails when considering broader system |

## Analysis-Specific Checks

Beyond the standard 5 components, apply these when critiquing analytical output:

| Check | Purpose | Key Questions |
| :---- | :------ | :------------ |
| **Blind Spots** | Areas not investigated | What parts of the codebase/system were not examined? |
| **Missing Evidence** | Claims without data | Which assertions lack supporting code, logs, or error messages? |
| **Alternative Root Causes** | Other explanations | What else could explain the findings? |
| **Confidence Calibration** | Rating accuracy | Are severity ratings justified by the evidence presented? |

## Counter-Argument Framework

1. **Steel-man the position**: Articulate the strongest version of the input
2. **Identify the skeptic**: Who would disagree and why?
3. **Generate objections**: List specific, concrete concerns
4. **Rate severity**: Critical / Major / Minor
5. **Propose mitigations**: How could the objection be addressed?

## Stress Test Dimensions

| Dimension | Test Variations |
| :-------- | :-------------- |
| Scale | What if the problem is 10x larger than described? |
| Context | What if key context was missed or misunderstood? |
| Time | What if the analysis is based on stale information? |
| Edge Cases | What about the worst-case scenario? |

## Output Template

```markdown
## Adversarial Analysis: [Subject]

### Critical Assumptions
| Assumption | Fragility | Challenge | If Wrong |
| :--------- | :-------- | :-------- | :------- |
| ... | High/Med/Low | ... | ... |

### Failure Modes
| Mode | Trigger | Probability | Impact | Mitigation |
| :--- | :------ | :---------- | :----- | :--------- |
| ... | ... | High/Med/Low | High/Med/Low | ... |

### Counter-Arguments
1. **[Objection]** (Severity: Critical/Major/Minor)
   - Basis: [Why skeptic believes this]
   - Mitigation: [How to address]

### Stress Test Results
| Dimension | Scenario | Outcome | Risk Level |
| :-------- | :------- | :------ | :--------- |
| ... | ... | ... | High/Med/Low |

### Blind Spots
- [Area not investigated and why it matters]

### Alternative Explanations
- [Other root cause] — [supporting evidence or lack thereof]

### Confidence Assessment
- **Overall Verdict**: Strong / Moderate / Weak
- **Evidence Quality**: [Assessment of supporting data]
- **Recommendation**: Proceed as-is / Revise specific areas / Reject and redo
```

## Best Practices

1. Be constructively critical — identify weaknesses WITH solutions
2. Be specific — "This fails because X" not "This might fail"
3. Prioritize by impact — catastrophic risks first
4. Challenge your own critique — avoid invalid objections
5. Separate fixable issues from fundamental flaws
6. Distinguish between "wrong" and "incomplete" — different remedies needed
