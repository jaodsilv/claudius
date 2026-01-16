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
- "The system should be fast" → Vague
- "The system shall load pages in under 2 seconds" → Specific

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
- "User experience should be good" → Not measurable
- "API response time shall not exceed 200ms for 95th percentile" → Measurable

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
- "All queries shall return results in <1ms" (without sufficient infrastructure) → Unachievable
- "Mobile app shall work on all devices from 2010 onwards" → May be impractical

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
- "The system shall support 47 languages" (for a regional product) → Not relevant
- "Users shall be able to download their data" (supporting privacy goals) → Relevant

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
- "The system shall be continuously improved" → No defined scope
- "FR-001: User authentication for mobile app v2.0" → Time-bound and scoped

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

### Poor Requirement (Fails SMART)

**Original**: "The system should be user-friendly and fast."

**Issues**:
- **S**: "User-friendly" is vague
- **M**: "Fast" has no measurable threshold
- **A**: Cannot assess without specifics
- **R**: No connection to user needs stated
- **T**: No scope or timeline

### Improved Requirement (Passes SMART)

<!-- markdownlint-disable MD013 -->
**Revised**: "FR-042: The checkout flow shall complete in 3 steps or fewer, with page load times under 2 seconds on 3G connections, to reduce cart abandonment for mobile users in v2.0."
<!-- markdownlint-enable MD013 -->

**Validation**:
- **S**: "3 steps or fewer", "under 2 seconds", "3G connections" - specific
- **M**: Step count and load time are measurable
- **A**: 2 seconds on 3G is realistic with optimization
- **R**: "reduce cart abandonment for mobile users" - user need
- **T**: "v2.0" - scoped to release

### More Examples

<!-- markdownlint-disable MD013 -->
**Requirement**: "FR-015: The API shall support OAuth 2.0 authentication with token refresh, returning 401 Unauthorized for invalid tokens within 50ms."
<!-- markdownlint-enable MD013 -->

| Criterion | Assessment |
|-----------|------------|
| Specific | OAuth 2.0, token refresh, 401 response - clear |
| Measurable | 50ms response time threshold |
| Achievable | Standard OAuth implementation |
| Relevant | Security requirement for API access |
| Time-bound | Implicit scope to API v1 |

<!-- markdownlint-disable MD013 -->
**Requirement**: "NFR-003: The system shall maintain 99.9% uptime during business hours (8am-8pm EST) with no more than 3 planned maintenance windows per quarter."
<!-- markdownlint-enable MD013 -->

| Criterion | Assessment |
|-----------|------------|
| Specific | 99.9% uptime, business hours defined, maintenance windows |
| Measurable | Uptime percentage, maintenance count |
| Achievable | 99.9% is a common SLA target |
| Relevant | Availability requirement for business users |
| Time-bound | Per quarter, business hours scope |

## SMART Validation Template

Use this template to validate each requirement:

```markdown
## Requirement: [ID]
**Statement**: [Full requirement text]

### SMART Validation
| Criterion | Pass/Fail | Evidence |
|-----------|-----------|----------|
| Specific | | |
| Measurable | | |
| Achievable | | |
| Relevant | | |
| Time-bound | | |

### Issues Found
[List any SMART criteria failures]

### Recommended Revision
[Improved requirement text if needed]
```

## Common Pitfalls

1. **Vague adjectives**: "fast", "easy", "intuitive" - replace with metrics
2. **Missing acceptance criteria**: Add testable conditions
3. **Scope creep**: Define boundaries explicitly
4. **Orphan requirements**: Always link to user needs or business goals
5. **Unrealistic expectations**: Validate feasibility early
6. **Open-ended scope**: Always define version or release boundaries

## Related Documentation

- See `moscow-guide.md` for prioritization framework
- Reference project constraints for achievability assessment
- Consult stakeholder requirements for relevance validation
