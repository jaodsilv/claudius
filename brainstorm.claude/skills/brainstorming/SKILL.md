---
name: brainstorm:brainstorming
description: >-
  Orchestrates requirements discovery through multi-agent analysis and Socratic dialogue.
  Invoked when exploring vague ideas, discovering requirements, or defining feature scope.
---

# Brainstorming Skill

## When to Invoke

1. User has vague software/feature idea to explore
2. Requirements discovery needed for new concept
3. Feature scope needs definition before implementation

## Workflow Phases

| Phase | Agent | Output |
|-------|-------|--------|
| 1. Dialogue | `brainstorm-facilitator` | Key insights, user needs |
| 2. Domain | `brainstorm-domain-explorer` | Market research report |
| 3. Technical | `brainstorm-technical-analyst` | Feasibility assessment |
| 4. Constraints | `brainstorm-constraint-analyst` | Constraint analysis |
| 5. Synthesis | `brainstorm-requirements-synthesizer` | Structured requirements |
| 6. Document | `brainstorm-specification-writer` | Final specification |

## Depth Levels

| Level | Rounds | Best For | Time |
|-------|--------|----------|------|
| shallow | 3 | Small features, extensions | 15-30 min |
| normal | 5 | New features, moderate complexity | 30-60 min |
| deep | 8 | New products, strategic features | 60-120 min |

## Commands

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

## Templates

Output document templates are available in references:

- `references/requirements-document.md` - Full requirements specification template
- `references/session-summary.md` - Executive summary template

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

| File | Contents |
|------|----------|
| `specification.md` | Complete specification with all sections |
| `requirements.md` | Prioritized requirements (MoSCoW) |
| `session-log.md` | Dialogue transcripts, phase outputs |
| `summary.md` | Executive summary, next steps |

## Quality Checklist

### Dialogue

- [ ] Core problem articulated
- [ ] Target users identified
- [ ] Key scenarios explored
- [ ] Assumptions surfaced
- [ ] Scope boundaries defined

### Requirements

- [ ] All requirements testable
- [ ] Priorities clear (MoSCoW)
- [ ] Dependencies mapped
- [ ] Conflicts resolved

### Technical

- [ ] Feasibility assessed
- [ ] Architecture options considered

- [ ] Risks identified

### Document

- [ ] Executive summary captures essence
- [ ] All sections complete
- [ ] Next steps actionable

## Integration

### With TDD Workflow

- Requirements inform test design
- Technical analysis guides architecture
- Constraints inform feasibility checks

### With Commits

- Link commits to requirements (FR-001, etc.)
- Reference constraints in messages
- Document trade-off decisions

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| Too little information | Ask specific questions, provide examples |
| Session going in circles | Summarize understanding, move to next phase |
| Requirements conflict | Document conflict, analyze trade-offs, escalate |
| Feasibility unclear | Flag for technical spike, document assumptions |
