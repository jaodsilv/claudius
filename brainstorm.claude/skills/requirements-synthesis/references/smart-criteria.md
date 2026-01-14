# SMART Criteria Framework

The SMART framework ensures that requirements are well-formed, testable, and actionable.

## Criteria Overview

| Criterion | Description | How to Validate |
|-----------|-------------|-----------------|
| **S**pecific | Unambiguous and clearly defined | Remove vague language; include what, who, when, where |
| **M**easurable | Can be verified and tested | Define acceptance criteria; specify metrics or thresholds |
| **A**chievable | Technically feasible within constraints | Review against technical constraints and resource availability |
| **R**elevant | Aligned with project goals and user needs | Map to user stories or business objectives |
| **T**ime-bound | Has clear scope and definition | Define completion scope; avoid open-ended requirements |

## Detailed Guidance

### Specific (S)

**Definition**: A requirement must be clear and unambiguous with no room for misinterpretation.

**How to Validate**:
- Can a developer implement it without asking clarification questions?
- Does it describe one specific behavior or feature?
- Are all terms and conditions explicitly stated?

**Anti-patterns**:
- "The system should be fast" → ❌ Too vague
- "The system shall load pages in under 2 seconds" → ✅ Specific

**Best Practices**:
- Use "shall" for mandatory requirements
- Use "should" for recommended requirements
- Include acceptance criteria
- Reference related requirements by ID

### Measurable (M)

**Definition**: A requirement must have objective criteria to determine when it's been met.

**How to Validate**:
- Can we write a test for this requirement?
- Are there quantifiable metrics (numbers, percentages, thresholds)?
- Can acceptance be objectively verified?

**Anti-patterns**:
- "User experience should be good" → ❌ Not measurable
- "API response time shall not exceed 200ms for 95th percentile" → ✅ Measurable

**Best Practices**:
- Define success metrics (response time, error rate, throughput)
- Specify measurable acceptance criteria
- Include target thresholds or ranges
- Document how measurement will be conducted

### Achievable (A)

**Definition**: A requirement must be technically feasible and implementable within constraints.

**How to Validate**:
- Do we have the required technology/skills?
- Are there known technical blockers?
- Does it fit within resource and timeline constraints?
- Have similar requirements been implemented before?

**Anti-patterns**:
- "All queries shall return results in <1ms" (without sufficient infrastructure) → ❌ Unachievable
- "Mobile app shall work on all devices from 2010 onwards" → ❌ May be impractical

**Best Practices**:
- Validate against technical constraints
- Review feasibility with technical team
- Document any assumptions about resources
- Consider implementation complexity
- Reference similar completed features

### Relevant (R)

**Definition**: A requirement must align with project goals and directly support user needs.

**How to Validate**:
- Does this requirement solve a real user problem?
- Is it aligned with project objectives?
- Is it within project scope?
- Would removing it impact the product's value?

**Anti-patterns**:
- "The system shall support 47 languages" (for a regional product) → ❌ Not relevant
- "Users shall be able to download their data" (supporting privacy goals) → ✅ Relevant

**Best Practices**:
- Map requirements to user stories or business goals
- Maintain traceability to user needs
- Challenge scope creep with relevance questions
- Document rationale for inclusion
- Link to business priorities or compliance requirements

### Time-bound (T)

**Definition**: A requirement must have a defined scope—clear boundaries about what is and isn't included.

**How to Validate**:
- Is the scope clearly defined?
- Are boundaries explicit (what's out of scope)?
- Is the requirement scoped to a specific phase or release?
- Would a developer know when they're done?

**Anti-patterns**:
- "The system shall be continuously improved" → ❌ No defined scope
- "FR-001: User authentication for mobile app v2.0" → ✅ Time-bound and scoped

**Best Practices**:
- Define version or release scope
- Specify initial scope vs. future enhancements
- List what's explicitly out of scope
- Include version constraints
- Define completion/acceptance date if applicable

## Validation Checklist

For each requirement, verify:

- [ ] **Specific**: Is it unambiguous with clear acceptance criteria?
- [ ] **Measurable**: Can we objectively verify it's been met?
- [ ] **Achievable**: Is it technically feasible within constraints?
- [ ] **Relevant**: Does it support project goals and user needs?
- [ ] **Time-bound**: Is the scope clearly defined?

## Examples

### ❌ Poor Requirement
