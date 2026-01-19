# Analysis Synthesis Templates

Output templates for the analysis-synthesizer agent to ensure consistent formatting across sessions.

## Full Output Template

Use this template for the complete unified analysis summary:

````markdown
# Unified Analysis Summary

## Executive Summary
**Topic**: [Feature/product name]
**Analysis Alignment**: [High/Medium/Low]
**Critical Findings**: [Top 2-3 insights from synthesis]

## Cross-Domain Insights

### Market-Technical Alignment
[How market expectations align with or challenge technical recommendations]

### Constraint-Architecture Interaction
[How constraints shape architectural decisions]

### Domain-Constraint Connections
[Where industry practices address or conflict with constraints]

## Technical-Constraint Alignment

| Technical Decision | Supporting Constraints | Conflicting Constraints | Resolution |
|-------------------|----------------------|-------------------------|------------|
| [Decision] | [Support] | [Conflict] | [How to resolve] |

## Identified Conflicts

### Critical Conflicts
**Conflict 1**: [Description]
- **Impact**: [Effect on project]
- **Stakeholder Decision Needed**: [What must be decided]
- **Options**: [Possible resolutions]

### Medium Priority Conflicts
[Same structure]

## Gaps and Unknowns

### Unified Gap Analysis

| Gap | Source Phase | Impact | Priority | Recommended Action |
|-----|--------------|--------|----------|-------------------|
| [Gap] | Domain/Tech/Constraint | H/M/L | 1-5 | [Action] |

### Open Questions by Category

#### Technical
1. [Question] - Impact: [Effect] - Priority: [H/M/L]

#### Business/Market
1. [Question] - Impact: [Effect] - Priority: [H/M/L]

#### Resource/Constraint
1. [Question] - Impact: [Effect] - Priority: [H/M/L]

## Synthesized Recommendations

### Reinforced Recommendations
[Recommendations supported by multiple analyses]

1. **[Recommendation]**
   - **Supporting Evidence**: Domain: [insight], Technical: [insight], Constraints: [insight]
   - **Confidence**: High
   - **Action**: [What to do]

### Conditional Recommendations
[Recommendations dependent on resolving conflicts]

1. **[Recommendation]**
   - **Condition**: [What must be resolved first]
   - **Alternative**: [If condition not met]

### Risk Mitigation Priorities

| Risk | Source | Combined Impact | Recommended Mitigation |
|------|--------|----------------|------------------------|
| [Risk] | Tech/Domain/Constraint | H/M/L | [Mitigation] |

## Dependency Analysis

### Critical Path Items
1. [Item] - Blocks: [What it blocks] - Sources: [Which analyses identified]

### Parallel Workstreams
[Activities that can proceed independently]

## Assumptions Requiring Validation

| Assumption | Source | Risk if Invalid | Validation Method |
|------------|--------|-----------------|-------------------|
| [Assumption] | Phase | [Risk] | [How to validate] |
````

## Compact Summary Template

Use this template (15-20 lines) for passing context to the requirements synthesizer:

````markdown
### Context for Requirements Synthesis

**Architecture direction**: [Recommended pattern with key constraints applied]

**Complexity adjusted**: [T-shirt size considering constraints and unknowns]

**Market alignment**: [How solution fits market/competitive landscape - key differentiators]

**Critical constraints**: [Top 3 constraints shaping requirements]
1. [Constraint 1]
2. [Constraint 2]
3. [Constraint 3]

**Unresolved trade-offs**: [Trade-offs requiring stakeholder decision]
1. [Trade-off 1]
2. [Trade-off 2]

**Risks to address**: [Combined technical and constraint risks with priorities]
1. [Risk 1] - Priority: [H/M/L]
2. [Risk 2] - Priority: [H/M/L]

**Recommended focus areas**: [Priority areas for requirements]
1. [Area 1] - Rationale: [Why priority]
2. [Area 2] - Rationale: [Why priority]

**Open questions**: [Top 3-5 questions to resolve before or during requirements phase]
````

## Usage Notes

1. **Full Output**: Generate for session log and detailed review
2. **Compact Summary**: Pass to requirements-synthesizer agent
3. **Alignment Levels**:
   - High: Analyses agree on direction, minor conflicts
   - Medium: Some contradictions, resolvable with decisions
   - Low: Major conflicts requiring significant stakeholder input
