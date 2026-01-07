---
name: brainstorm:constraint-analysis
description: >-
  Identifies and categorizes constraints that shape solution design. Use when analyzing project constraints, identifying trade-offs, or documenting boundaries.
---

# Constraint Analysis

Identifies and categorizes constraints that shape solution design. Use when analyzing project constraints, identifying trade-offs, or documenting boundaries.

## When to Use

- During requirements gathering to surface hidden constraints
- When evaluating solution feasibility
- To identify trade-offs between competing requirements
- When prioritizing work or managing stakeholder expectations

## Constraint Categories

The skill covers four primary constraint dimensions:

- **Technical**: Platform, stack, integration, performance, security, scalability, availability
- **Business**: Budget, timeline, compliance, brand, legal, stakeholder
- **Resource**: Team, skills, infrastructure, third-party, support
- **Environmental**: Network, device, geographic, user

See `references/constraint-taxonomies.md` for the full taxonomy with descriptions and examples for each constraint type.

## Trade-off Analysis

Constraints often conflict, requiring trade-off analysis. The skill provides:

- Patterns for identifying conflicting constraints
- Framework for assessing constraint properties (type, source, impact, negotiability)
- Mitigation strategies and creative workarounds

See `references/trade-off-patterns.md` for detailed trade-off analysis patterns.

## Output Format

Provide a compact summary including:

- **Top 3-5 critical constraints** ranked by impact and negotiability
- **Key trade-offs identified** showing conflicting constraints
- **Recommended mitigations** for hard constraints
- **Questions for stakeholders** to clarify soft constraints
- **Impact matrix** showing which requirements are affected

## Discovery Questions

Ask systematically across categories:
- **Technical**: Systems to integrate? Platforms? Performance needs? Security standards?
- **Business**: Budget? Launch date? Regulations? Required approvals?
- **Resource**: Team size? Available skills? Infrastructure? Vendors?
- **Environmental**: Access locations? Devices? Network conditions? User skill levels?

## Best Practices

1. Ask clarifying questions about stated constraints
2. Distinguish real constraints from perceived constraints
3. Identify hidden constraints embedded in requirements
4. Consider second-order effects and constraint combinations
5. Document constraint sources for escalation and validation
6. Propose creative mitigations and workarounds
