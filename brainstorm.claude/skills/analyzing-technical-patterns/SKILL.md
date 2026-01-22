---
name: brainstorm:analyzing-technical-patterns
description: >-
  Evaluates technical feasibility and architecture options. Invoked during brainstorm Phase 3
  to assess implementation approaches, compare architectures, and estimate complexity.
allowed-tools:
model: sonnet
---

# Technical Patterns Skill

Evaluates technical feasibility and architecture options for proposed features.

## When to Use

- During Phase 3 (Technical Feasibility Analysis) of brainstorm workflow
- When assessing multiple implementation approaches
- When estimating project complexity and effort
- When identifying technical risks and unknowns

## Architecture Patterns

Reference `references/architecture-patterns.md` for detailed analysis of:

- **Monolithic architecture** - Single unified codebase
- **Microservices architecture** - Independent deployable services
- **Event-driven architecture** - Asynchronous event-based flows
- **Serverless architecture** - Function-based cloud execution
- **Modular monolith** - Organized internal modules with boundaries

Each pattern includes trade-off analysis, use cases, and comparison criteria.

## Complexity Sizing

Reference `references/complexity-sizing.md` for:

- **T-shirt sizing methodology** (XS to XL) with effort ranges
- **Complexity factors** that influence estimates
- **Assessment approach** for each dimension

## Analysis Dimensions

| Dimension | Factors |
|-----------|---------|
| Implementation | Algorithm, data model, integration, UI/UX |
| Technology Fit | Stack compatibility, frameworks, performance, scalability |
| Resources | Effort, infrastructure, third-party dependencies, maintenance |
| Risk | Technical unknowns, performance, security, failure cascades |

## Output Format

Provide a compact technical analysis:

1. **Feasibility Assessment** - High/Medium/Low with key factors
2. **Architecture Recommendation** - Selected pattern with rationale
3. **Complexity Estimate** - T-shirt size with effort range
4. **Top 3 Technical Risks** - With likelihood, impact, mitigation
5. **Technology Recommendations** - Stack choices by layer
6. **Prerequisites** - Technical spikes and decisions needed
7. **Open Questions** - Areas requiring investigation

## Integration

- Outputs inform requirements prioritization
- Complexity estimates guide phasing and resource planning
- Risk assessments shape technical spike decisions
- Architecture recommendations drive team skills assessment
