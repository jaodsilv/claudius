# Trade-off Analysis Patterns

Patterns and frameworks for identifying, analyzing, and resolving constraint conflicts.

## Trade-off Identification

Constraints often conflict, requiring explicit trade-off analysis and resolution.

### Common Conflict Patterns

| Pattern | Constraints | Tension | Example |
|---------|-----------|---------|---------|
| **Speed vs. Quality** | Timeline + Security/Performance | Faster delivery vs. more testing | 6-month launch requires cutting security review |
| **Cost vs. Scale** | Budget + Scalability | Lower cost vs. supporting growth | $100K budget cannot support 1M users |
| **Features vs. Timeline** | Scope + Timeline | Feature completeness vs. launch date | All features cannot ship in 6 months |
| **Flexibility vs. Performance** | Architecture + Performance | Flexible design vs. speed optimization | Generic solution slower than specialized |
| **Team Size vs. Complexity** | Team + Technical Stack | Smaller team vs. complex technology | 4-person team cannot master multiple tech stacks |
| **Cost vs. Security** | Budget + Security | Cost savings vs. security standards | Encryption adds infrastructure cost |
| **Brand Consistency vs. Innovation** | Brand + Technical | Design guidelines vs. new approaches | Design system limits modern component options |
| **Compliance vs. Speed** | Compliance + Timeline | Regulatory requirements vs. fast launch | HIPAA audit adds 3 months |

## Trade-off Analysis Structure

### Step 1: Identify Conflicting Constraints

```
Constraint A: [Name] (Type: [category])
- Impact: [H/M/L]
- Negotiability: [Hard/Soft]
- Current Status: [What does it require]

Constraint B: [Name] (Type: [category])
- Impact: [H/M/L]
- Negotiability: [Hard/Soft]
- Current Status: [What does it require]

Conflict: [How they contradict]
```

### Step 2: Analyze Constraint Properties

For each constraint in the trade-off:

| Property | Meaning | Questions |
|----------|---------|-----------|
| **Impact** | How much it affects the solution | Is it really high impact? What if we ignore it? |
| **Negotiability** | Can it be changed | Who decided this? Could they change their mind? |
| **Source** | Where it came from | Is it a hard requirement or a preference? |
| **Hidden Drivers** | Why it's a constraint | What problem does it solve? What happens if violated? |
| **Validation** | How confirmed | Is this definitely required? How do we know? |

### Step 3: Explore Resolution Options

For each option, evaluate:

```markdown
### Option 1: [Name]
**Approach**: [What we would do]
**Favors**: [Which constraint is satisfied]
**Sacrifices**: [Which constraint is compromised]
**Timeline Impact**: [How does it affect schedule]
**Cost Impact**: [How does it affect budget]
**Risk**: [What could go wrong]
**Recommended**: [Yes/No and why]

### Option 2: [Alternative approach]
[Same structure]
```

## Resolution Options Framework

### Technical Solutions

1. **Technology Substitution**: Use different tools/frameworks to satisfy constraints
   - Example: Replace relational DB with NoSQL for scalability
   - Trade-off: Different dev skills required

2. **Architectural Refactoring**: Restructure the system to reduce conflicts
   - Example: Microservices for scaling teams
   - Trade-off: Increased operational complexity

3. **Phased Approach**: Split requirements across releases
   - Example: MVP without advanced features, Phase 2 adds complexity
   - Trade-off: Longer overall timeline

4. **Hybrid Solution**: Combine different approaches for different parts
   - Example: Critical path fully tested, non-critical path lighter testing
   - Trade-off: Inconsistent quality levels

### Business Solutions

1. **Scope Reduction**: Remove lower-priority requirements
   - Example: Cut "nice-to-have" features to meet timeline
   - Trade-off: Less complete solution initially

2. **Timeline Extension**: Negotiate longer delivery window
   - Example: Request 3-month extension for compliance
   - Trade-off: Delayed market entry

3. **Budget Increase**: Allocate more resources
   - Example: Hire contractors to accelerate delivery
   - Trade-off: Higher cost, integration complexity

4. **Constraint Relaxation**: Negotiate softer constraint boundaries
   - Example: Accept 99.9% SLA instead of 99.99%
   - Trade-off: Lower reliability target

### Resource Solutions

1. **Team Expansion**: Add specialized skills
   - Example: Hire security expert for compliance
   - Trade-off: Onboarding time, increased cost

2. **Training**: Build internal expertise
   - Example: Train team on new technology stack
   - Trade-off: Learning curve affects velocity

3. **Outsourcing**: Contract specialized work
   - Example: Outsource DevOps/infrastructure
   - Trade-off: Less internal knowledge, vendor risk

4. **Process Improvement**: Increase team efficiency
   - Example: Improved code review process, automation
   - Trade-off: Upfront setup time

## Constraint Combination Analysis

### Identifying Second-Order Conflicts

When resolving one trade-off, check if the resolution creates new conflicts:

```markdown
### Resolution Impact Analysis

**Original Trade-off**: A vs B
**Resolution**: Chose Option X
**New Constraint Created**: C
**New Conflict**: X partially violates constraint C
**Next Steps**: Analyze A vs B vs C three-way trade-off
```

### Three-Way Trade-offs

When three or more constraints conflict:

1. **Rank by Impact**: Which is most critical?
2. **Identify Core Conflict**: Which two are most in tension?
3. **Find Relaxations**: Which constraint could be negotiated?
4. **Propose Hybrid**: Can we partially satisfy all three?

## Decision Documentation

### Trade-off Decision Record

```markdown
## Trade-off: [Name]

**Date**: [YYYY-MM-DD]
**Decision**: [What we chose]
**Rationale**: [Why this option]

**Constraints Involved**:
- [Constraint A] (Source, Impact, Negotiability)
- [Constraint B] (Source, Impact, Negotiability)

**Options Evaluated**:
| Option | Impact | Risk | Score |
| Option A | ... | ... | 8/10 |
| Option B | ... | ... | 5/10 |

**Recommendation**: Option A because [reasons]

**Implementation**:
- [Action 1]
- [Action 2]

**Monitoring**:
- Success metric: [How we'll know it worked]
- Review date: [When to reassess]
```

## Mitigation Strategies

### For Hard Constraints

When constraints cannot be negotiated, mitigate impact:

1. **Accept and Optimize**: Live with constraint, minimize its effect
   - Example: Platform limitation → optimize for that platform specifically

2. **Work Around**: Find creative solutions that satisfy both
   - Example: Security constraint + timeline pressure → use proven secure patterns

3. **Phase the Solution**: Implement constraint-satisfying features later
   - Example: Compliance requirement → deliver core features, add compliance in Phase 2

4. **Isolate Impact**: Limit constraint's reach to necessary areas only
   - Example: Performance requirement → cache heavily, optimize critical path

### For Soft Constraints

When constraints can be negotiated:

1. **Renegotiate**: Ask stakeholder if constraint can be relaxed
   - Ask: "What happens if we do X instead?"
   - Document: Who agreed to relaxation, on what terms

2. **Find Triggers**: Identify conditions that change negotiability
   - Example: Budget constraint becomes softer if timeline is tight
   - Use as leverage in negotiation

3. **Progressive Validation**: Test whether constraint is actually needed
   - Example: Performance requirement → build prototype, measure actual needs

## Stakeholder Communication

### Presenting Trade-offs

When presenting options to stakeholders:

1. **Show the Conflict**: Make trade-off explicit
   - "We can do A or B, but not both with current constraints"

2. **Present Real Options**: Give 2-3 genuine alternatives
   - Option 1: Favors A, sacrifices B
   - Option 2: Favors B, sacrifices A
   - Option 3: Partial solution for both

3. **Show Consequences**: Be clear about impacts
   - Timeline impact, budget impact, quality impact, risk

4. **Recommend**: Don't hide behind "it's your decision"
   - State which option you recommend and why

5. **Document Decision**: Confirm choice and rationale in writing

## Constraint Relaxation Patterns

### Questions to Ask About Constraints

- **"Is this truly fixed?"**: Could this constraint be relaxed?
- **"What if we violated it slightly?"**: What would actually happen?
- **"Who decided this?"**: Can they reconsider?
- **"What problem does it solve?"**: Could we solve it differently?
- **"What's the minimum acceptable?"**: Can we negotiate boundaries?

### Negotiation Triggers

Constraints become negotiable when:
- **Timeline pressure**: Tight deadlines make budgets flexible
- **Market opportunity**: Business value allows budget relaxation
- **Technical impossibility**: Impossible constraints must be relaxed
- **Cost benefit**: Clear ROI for relaxation justifies investment
- **Risk mitigation**: High-risk constraints can be relaxed with mitigations
