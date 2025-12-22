---
name: Prioritization Frameworks
description: This skill should be used when the user asks to "prioritize issues", "rank features", "apply RICE scoring", "use MoSCoW prioritization", "create a priority matrix", or needs to systematically compare and rank items.
version: 1.0.0
---

# Prioritization Frameworks

Apply systematic prioritization frameworks to rank issues, features, tasks, or any items requiring comparative evaluation.

## Framework Selection

Choose the appropriate framework based on context:

| Framework | Best For | Key Inputs |
|-----------|----------|------------|
| RICE | Data-driven product decisions | Reach, impact estimates |
| MoSCoW | Stakeholder-driven prioritization | Business criticality |
| Weighted Scoring | Custom criteria evaluation | Defined criteria weights |
| Kano Model | User satisfaction analysis | User research data |
| Value vs Effort | Quick visual prioritization | Rough estimates |

## RICE Framework

### Formula

```
RICE Score = (Reach × Impact × Confidence) / Effort
```

### Components

1. **Reach** (number of users/events in time period)
   - How many users will this affect in a quarter?
   - Use concrete numbers when possible

2. **Impact** (per-user impact score)
   - 3 = Massive (transformative)
   - 2 = High (significant improvement)
   - 1 = Medium (noticeable improvement)
   - 0.5 = Low (minor improvement)
   - 0.25 = Minimal (barely noticeable)

3. **Confidence** (estimate reliability)
   - 100% = High confidence, solid data
   - 80% = Medium confidence, some data
   - 50% = Low confidence, mostly intuition

4. **Effort** (person-weeks or person-months)
   - Engineering time required
   - Include all team members

### RICE Scoring Process

1. List all items to prioritize
2. For each item, estimate:
   - Reach: How many users affected per quarter?
   - Impact: What's the per-user impact? (3/2/1/0.5/0.25)
   - Confidence: How confident are estimates? (100/80/50)
   - Effort: Person-weeks required
3. Calculate RICE score
4. Rank by score (higher = higher priority)

### RICE Output Template

```markdown
| Rank | Item | Reach | Impact | Confidence | Effort | Score |
|------|------|-------|--------|------------|--------|-------|
| 1 | Feature A | 10000 | 2 | 80% | 4 | 4000 |
| 2 | Feature B | 5000 | 3 | 100% | 6 | 2500 |
```

## MoSCoW Framework

### Categories

1. **Must Have** (Critical)
   - Without this, the project fails
   - Non-negotiable requirements
   - Core functionality

2. **Should Have** (Important)
   - Important but not critical
   - Significant value
   - Can work around if needed

3. **Could Have** (Desirable)
   - Nice to have
   - Enhances experience
   - Lower priority than Should

4. **Won't Have** (Out of Scope)
   - Explicitly excluded
   - Not this release
   - May be future consideration

### MoSCoW Guidelines

- Must Have: No more than 60% of effort
- Should Have: ~20% of effort
- Could Have: ~20% of effort
- Validate with stakeholders

### MoSCoW Output Template

```markdown
## Must Have (Critical)
1. [Item] - [Rationale]

## Should Have (Important)
1. [Item] - [Rationale]

## Could Have (Desirable)
1. [Item] - [Rationale]

## Won't Have (This Release)
1. [Item] - [Reason for exclusion]
```

## Weighted Scoring

### Process

1. Define evaluation criteria
2. Assign weights to each criterion (total = 100%)
3. Score each item per criterion (1-10)
4. Calculate weighted total

### Common Criteria

| Criterion | Description | Typical Weight |
|-----------|-------------|----------------|
| Business Value | Revenue/strategic impact | 25-35% |
| User Value | User satisfaction impact | 20-30% |
| Technical Feasibility | Implementation complexity | 15-25% |
| Strategic Alignment | Fits company goals | 10-20% |
| Risk | Implementation risk | 10-15% |

### Weighted Scoring Template

```markdown
| Item | Value (30%) | Feasibility (25%) | Alignment (25%) | Risk (20%) | Total |
|------|-------------|-------------------|-----------------|------------|-------|
| A | 8 (2.4) | 6 (1.5) | 9 (2.25) | 7 (1.4) | 7.55 |
| B | 7 (2.1) | 8 (2.0) | 7 (1.75) | 8 (1.6) | 7.45 |
```

## Kano Model

### Categories

1. **Basic Needs** (Must-Be)
   - Expected, taken for granted
   - Absence causes dissatisfaction
   - Presence doesn't increase satisfaction

2. **Performance Needs** (One-Dimensional)
   - More is better
   - Linear relationship with satisfaction
   - Competitive differentiators

3. **Excitement Needs** (Attractive)
   - Unexpected delighters
   - Absence doesn't cause dissatisfaction
   - Presence creates strong satisfaction

4. **Indifferent**
   - No impact on satisfaction

5. **Reverse**
   - Causes dissatisfaction when present

### Kano Classification Questions

For each feature, ask users:
1. "How would you feel if this feature IS present?" (Functional)
2. "How would you feel if this feature IS NOT present?" (Dysfunctional)

Answer options: Like, Expect, Neutral, Tolerate, Dislike

## Value vs Effort Matrix

### Quadrants

```
High Value │  Quick Wins  │  Major Projects
           │  (Do First)  │  (Plan Carefully)
           │──────────────┼──────────────────
Low Value  │   Fill-Ins   │  Time Sinks
           │  (Do Later)  │  (Avoid)
           └──────────────┴──────────────────
              Low Effort     High Effort
```

### Prioritization Order

1. **Quick Wins** (High Value, Low Effort) - Do immediately
2. **Major Projects** (High Value, High Effort) - Plan and schedule
3. **Fill-Ins** (Low Value, Low Effort) - Do when time permits
4. **Time Sinks** (Low Value, High Effort) - Avoid or defer

## GitHub Issue Labels Interpretation

When prioritizing GitHub issues, interpret common labels:

### Priority Labels
- `P0`, `critical`, `blocker` → Must Have / Score boost
- `P1`, `high-priority` → Should Have / High value
- `P2`, `medium` → Could Have / Medium value
- `P3`, `low` → Lower priority

### Effort Labels
- `XS`, `trivial` → 0.5 person-days
- `S`, `small` → 1-2 person-days
- `M`, `medium` → 3-5 person-days
- `L`, `large` → 1-2 person-weeks
- `XL`, `epic` → 2+ person-weeks

### Type Labels
- `bug` → Often higher priority (affects existing users)
- `feature` → Evaluate by framework
- `enhancement` → Improvements to existing features
- `tech-debt` → Consider long-term impact
- `security` → Usually highest priority

## Integration with GitHub

Fetch issues using gh CLI:

```bash
# Get all open issues with details
gh issue list --json number,title,labels,body,comments,milestone

# Get specific issue
gh issue view <number> --json number,title,body,labels,state
```

Parse labels to inform prioritization:
1. Extract priority labels for initial ranking
2. Extract effort labels for RICE effort estimate
3. Use milestone for timeline constraints
4. Parse body for dependencies ("blocked by #X")

## Best Practices

1. **Involve stakeholders** - Prioritization is collaborative
2. **Document rationale** - Record why items are ranked
3. **Revisit regularly** - Priorities change
4. **Consider dependencies** - Blocked items may need reordering
5. **Balance frameworks** - Use multiple methods for validation
6. **Be honest about estimates** - Use confidence scores
7. **Set aside time** - Prioritization requires focus
