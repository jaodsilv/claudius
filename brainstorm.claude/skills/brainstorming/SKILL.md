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
| 1. Dialogue | `brainstorm:facilitator` | Key insights, user needs (batched 2-3 rounds) |
| 2-4. Analysis | `brainstorm:domain-explorer`, `brainstorm:technical-analyst`, `brainstorm:constraint-analyst` | Parallel analysis reports |
| 4.5. Synthesis | `brainstorm:analysis-synthesizer` | Unified analysis context |
| 5. Requirements | `brainstorm:requirements-synthesizer` | Structured requirements |
| 6. Document | `brainstorm:specification-writer` | Final specification |

**Note**: Phases 2-4 execute in parallel for efficiency. Phase 4.5 merges their outputs before requirements synthesis.

## Depth Levels

| Level | Rounds | Best For | Time |
|-------|--------|----------|------|
| shallow | 3 | Small features, extensions | 15-30 min |
| normal | 5 | New features, moderate complexity | 30-60 min |
| deep | 8 | New products, strategic features | 60-120 min |

## Commands

| Command | Purpose |
|---------|---------|
| `/brainstorm:start` | Start new session |
| `/brainstorm:continue` | Resume interrupted session |
| `/brainstorm:export` | Regenerate documents |

## Output Artifacts

| File | Contents |
|------|----------|
| `specification.md` | Complete specification with all sections |
| `requirements.md` | Prioritized requirements (MoSCoW) |
| `session-log.md` | Dialogue transcripts, phase outputs |
| `summary.md` | Executive summary, next steps |

## Templates

Output document templates are available in references:

- `references/requirements-document.md` - Full requirements specification template
- `references/session-summary.md` - Executive summary template

## Related Skills

The brainstorming workflow leverages these specialized skills:

- `constraint-analysis` - Constraint identification and trade-off patterns
- `technical-patterns` - Architecture pattern selection and complexity sizing
- `requirements-synthesis` - SMART criteria and MoSCoW prioritization
- `domain-research` - Domain exploration research areas
- `workflow-validation` - Quality gates between phases

Each skill provides detailed reference material used by the corresponding agents.

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
