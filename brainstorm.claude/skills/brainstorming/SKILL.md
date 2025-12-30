---
name: brainstorm:brainstorming
description: >-
  Provides a systematic approach to requirements discovery through Socratic dialogue
  and multi-agent analysis, transforming ambiguous ideas into actionable specifications.
---

# Brainstorming Skill

## When to Use This Skill

This skill is automatically invoked when:

1. User has a vague software/feature idea to explore
2. Requirements discovery is needed for a new concept
3. Systematic exploration of possibilities is requested
4. User wants to brainstorm before implementation
5. Feature scope needs to be defined

## Overview

The brainstorming skill provides a systematic approach to requirements discovery
through Socratic dialogue and multi-agent analysis. It transforms ambiguous ideas
into actionable specifications.

## Core Principles

1. **Question Before Answer**: Explore through questions, not assumptions
2. **Multi-Perspective Analysis**: Technical, business, user, and domain views
3. **Progressive Refinement**: Start broad, narrow systematically
4. **Document Everything**: Capture insights for future reference
5. **Actionable Outputs**: End with concrete next steps

## Workflow Summary

The brainstorming workflow consists of 6 phases:

### Phase 1: Socratic Dialogue

1. Facilitator agent conducts structured questioning
2. Explores problem, users, scope, constraints, edge cases
3. Number of rounds based on depth setting
4. Produces dialogue summary with key insights

### Phase 2: Domain Exploration

1. Domain explorer researches market landscape
2. Analyzes competitors and best practices
3. Identifies user expectations and patterns
4. Produces domain research report

### Phase 3: Technical Analysis

1. Technical analyst evaluates feasibility
2. Proposes architecture options
3. Assesses complexity and risks
4. Produces technical analysis report

### Phase 4: Constraint Analysis

1. Constraint analyst identifies limitations
2. Categorizes technical, business, resource constraints
3. Analyzes trade-offs and conflicts
4. Produces constraint analysis report

### Phase 5: Requirements Synthesis

1. Requirements synthesizer consolidates all inputs
2. Formulates SMART requirements
3. Prioritizes using MoSCoW method
4. Produces structured requirements document

### Phase 6: Document Generation

1. Specification writer integrates all outputs
2. Applies consistent document structure
3. Produces comprehensive specification
4. Generates session summary

## Depth Levels

### Shallow (3 dialogue rounds)

1. Quick exploration for well-defined concepts
2. Best for: Small features, extensions to existing systems
3. Estimated time: 15-30 minutes

### Normal (5 dialogue rounds)

1. Standard exploration for new features
2. Best for: New features, moderate complexity
3. Estimated time: 30-60 minutes

### Deep (8 dialogue rounds)

1. Comprehensive exploration for complex concepts
2. Best for: New products, strategic features, high-risk items
3. Estimated time: 60-120 minutes

## Available Commands

| Command | Purpose |
|---------|---------|
| `/brainstorm:start` | Start a new brainstorming session |
| `/brainstorm:continue` | Resume an interrupted session |
| `/brainstorm:export` | Regenerate session documents |

## Available Agents

| Agent | Purpose |
|-------|---------|
| `brainstorm-facilitator` | Drives Socratic dialogue |
| `brainstorm-domain-explorer` | Researches market and domain |
| `brainstorm-technical-analyst` | Evaluates technical feasibility |
| `brainstorm-constraint-analyst` | Identifies constraints |
| `brainstorm-requirements-synthesizer` | Consolidates requirements |
| `brainstorm-specification-writer` | Generates final documents |

## Quality Checklist

### Dialogue Quality

1. [ ] Core problem clearly articulated
2. [ ] Target users identified and understood
3. [ ] Key scenarios explored
4. [ ] Assumptions surfaced
5. [ ] Scope boundaries defined

### Requirements Quality

1. [ ] All requirements are testable
2. [ ] Priorities are clear (MoSCoW)
3. [ ] Dependencies mapped
4. [ ] Conflicts resolved
5. [ ] Gaps documented

### Technical Quality

1. [ ] Feasibility assessed
2. [ ] Architecture options considered
3. [ ] Risks identified
4. [ ] Complexity estimated
5. [ ] Technology recommendations provided

### Document Quality

1. [ ] Executive summary captures essence
2. [ ] All sections complete
3. [ ] Cross-references accurate
4. [ ] Next steps actionable
5. [ ] Open questions documented

## Best Practices

### DO

1. Let the user drive the vision
2. Ask clarifying questions
3. Surface hidden assumptions
4. Consider edge cases
5. Document trade-off decisions
6. Provide concrete examples
7. Flag areas needing more research

### DO NOT

1. Assume requirements
2. Jump to solutions too early
3. Ignore constraints
4. Skip the dialogue phase
5. Provide vague requirements
6. Forget non-functional requirements
7. Leave questions unaddressed

## Integration with Other Skills

### TDD Workflow

After brainstorming, use the TDD workflow for implementation:

1. Requirements from brainstorm inform test design
2. Technical analysis guides architecture decisions
3. Constraints inform feasibility checks

### Code Quality

Apply code quality standards from brainstorm insights:

1. Non-functional requirements define quality targets
2. Technical constraints inform code patterns
3. User expectations guide UX decisions

### Conventional Commits

Reference brainstorm sessions in commits:

1. Link commits to requirements (FR-001, etc.)
2. Reference constraints in commit messages
3. Document trade-off decisions

## Troubleshooting

### User provides too little information

1. Ask more specific questions
2. Provide examples to anchor discussion
3. Break down into smaller areas
4. Use hypothetical scenarios

### Session going in circles

1. Summarize current understanding
2. Identify specific blockers
3. Suggest moving to next phase
4. Ask what would help clarify

### Requirements conflict

1. Document the conflict explicitly
2. Analyze trade-offs
3. Escalate decision to stakeholders
4. Propose resolution options

### Technical feasibility unclear

1. Flag for deeper technical spike
2. Document assumptions
3. Plan validation steps
4. Identify proof-of-concept needs

## Output Artifacts

### specification.md

Complete specification document containing:

1. Executive summary
2. Problem statement and users
3. Solution overview
4. All requirements (functional and non-functional)
5. Technical considerations
6. Constraints and risks
7. Next steps

### requirements.md

Structured requirements document containing:

1. Functional requirements by priority
2. Non-functional requirements
3. Constraints and assumptions
4. Dependency map
5. Gaps and open questions

### session-log.md

Complete session record containing:

1. Session metadata
2. Dialogue transcripts
3. Phase outputs
4. Insights captured
5. Decisions made

### summary.md

Executive summary containing:

1. Key outcomes
2. Generated artifacts
3. Recommended next steps
4. Open questions

## Tips for Effective Brainstorming

1. **Start with "Why"**: Begin by understanding why this feature matters
2. **Think in Scenarios**: Explore concrete use cases, not abstract features
3. **Challenge Assumptions**: Question everything that seems obvious
4. **Consider Trade-offs**: Every decision has consequences
5. **Document as You Go**: Capture insights immediately
6. **Stay Open-minded**: Early ideas often evolve significantly
7. **Know When to Stop**: Diminishing returns signal readiness to proceed
